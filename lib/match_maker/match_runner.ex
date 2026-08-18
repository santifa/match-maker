defmodule MatchMaker.MatchRunner do
  alias MatchMaker.Collections
  alias MatchMaker.Collections.Match
  require Logger

  def run(collection) do
    left_items = collection.left_items |> Enum.filter(fn i -> i.enabled end)
    right_items = collection.right_items |> Enum.filter(fn i -> i.enabled end)

    case {left_items, right_items} do
      {[], _} ->
        {:error, "Not enough people for a match"}

      {_, []} ->
        {:error, "Not enough tasks for a match"}

      {left_items, right_items} ->
        algorithm = matching_algorithm(collection)

        history =
          if algorithm == :greedy_history_aware,
            do: Collections.list_pair_history(collection.id),
            else: %{}

        assignments = assign_items(algorithm, left_items, right_items, history)

        with :ok <- validate_all_pairs(collection, assignments) do
          match = Collections.create_match(collection, assignments)
          maybe_send_webhook(collection, assignments)
          match
        end
    end
  end

  defp matching_algorithm(%{matching_algorithm: algorithm})
       when algorithm in [:randomized_round_robin, :greedy_history_aware],
       do: algorithm

  defp matching_algorithm(_collection), do: :randomized_round_robin

  defp assign_items(:randomized_round_robin, left_items, right_items, _history) do
    right_items = for i <- right_items, i.enabled, do: i
    left_items = for i <- left_items, i.enabled, do: i

    # Multiple left-hand sides are allowed, but all are chosen at least once when
    # there are enough right-hand sides.
    left_items =
      left_items
      |> Enum.shuffle()
      |> Stream.cycle()
      |> Enum.take(length(right_items))

    right_items = Enum.shuffle(right_items)
    Enum.zip_with(right_items, left_items, fn r, l -> {r.id, l.id} end)
  end

  defp assign_items(:greedy_history_aware, left_items, right_items, history) do
    right_items
    |> Enum.shuffle()
    |> Enum.reduce({MapSet.new(), []}, fn right, {used_left_ids, assignments} ->
      available_left_items = Enum.reject(left_items, &MapSet.member?(used_left_ids, &1.id))
      candidates = if available_left_items == [], do: left_items, else: available_left_items

      left =
        candidates
        |> Enum.map(fn candidate ->
          {Map.get(history, {candidate.id, right.id}, 0), candidate}
        end)
        |> choose_lowest_cost()

      {
        MapSet.put(used_left_ids, left.id),
        [{right.id, left.id} | assignments]
      }
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  defp choose_lowest_cost(candidates) do
    lowest_cost = candidates |> Enum.map(&elem(&1, 0)) |> Enum.min()

    candidates
    |> Enum.filter(&(elem(&1, 0) == lowest_cost))
    |> Enum.shuffle()
    |> hd()
    |> elem(1)
  end

  defp validate_all_pairs(collection, assignments) do
    Enum.reduce_while(assignments, :ok, fn {right_id, left_id}, _acc ->
      left = Enum.find(collection.left_items, &(&1.id == left_id))
      right = Enum.find(collection.right_items, &(&1.id == right_id))

      case Collections.validate_item_pair(%Match{collection_id: collection.id}, left, right) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  def maybe_send_webhook(%{webhook_url: nil}, _), do: :noop
  def maybe_send_webhook(%{webhook_url: ""}, _), do: :noop

  def maybe_send_webhook(%{webhook_url: url}, assignments) do
    body =
      %{
        content:
          Enum.join(
            Enum.map(assignments, fn {r, l} ->
              r = Collections.get_item!(r)
              l = Collections.get_item!(l)

              if r do
                "#{l.name} -> #{r.name}"
              end
            end),
            "\n"
          )
      }
      |> Jason.encode!()

    request =
      Finch.build(:post, url, [{"content-type", "application/json"}], body)

    case Finch.request(request, MatchMaker.Finch) do
      {:ok, %Finch.Response{status: code}} when code in 200..299 ->
        :ok

      {:ok, %Finch.Response{status: code, body: body}} ->
        Logger.error("Webhook returned #{code}: #{body}")
        {:error, :unexpected_response}

      {:error, reason} ->
        Logger.error("Webhook failed: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
