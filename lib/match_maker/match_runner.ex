defmodule MatchMaker.MatchRunner do
  alias MatchMaker.Collections
  alias MatchMaker.Collections.Match
  require Logger

  def run(collection) do
    left_items = collection.left_items
    right_items = Enum.shuffle(collection.right_items)

    case {left_items, right_items} do
      {[], _} ->
        {:error, "Not enough people for a match"}

      {_, []} ->
        {:error, "Not enough tasks for a match"}

      {left_items, right_items} ->
        assignments = assign_items(left_items, right_items)

        with :ok <- validate_all_pairs(collection, assignments) do
          match = Collections.create_match(collection, assignments)
          maybe_send_webhook(collection, assignments)
          match
        end
    end
  end

  defp assign_items(left_items, right_items) do
    right_items = for i <- right_items, i.enabled, do: i
    left_items = for i <- left_items, i.enabled, do: i

    # multiple left hand sides are allowed but only if all are chosen at least once
    left_items =
      left_items
      |> Enum.shuffle
      |> Stream.cycle
      |> Enum.take(length(right_items))

    Enum.zip_with(right_items, left_items, fn r, l -> {r.id, l.id} end)
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
