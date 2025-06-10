defmodule MatchMaker.MatchRunner do
  alias MatchMaker.Collections
  alias MatchMaker.Collections.Match

  def run(collection) do
    left_items = collection.left_items
    right_items = Enum.shuffle(collection.right_items)
    IO.puts("Here")

    assignments =
      Enum.map(right_items, fn right ->
        {right.id, Enum.random(left_items).id}
      end)

    with :ok <- validate_all_pairs(collection, assignments) do
      Collections.create_match(collection, assignments)
    end
  end

  defp validate_all_pairs(collection, assignments) do
    Enum.reduce_while(assignments, :ok, fn {right_id, left_id}, _acc ->
      left  = Enum.find(collection.left_items,  &(&1.id == left_id))
      right = Enum.find(collection.right_items, &(&1.id == right_id))

      case Collections.validate_item_pair(%Match{collection_id: collection.id}, left, right) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end
end
