defmodule MatchMaker.MatchRunnerTest do
  use MatchMaker.DataCase

  alias MatchMaker.MatchRunner
  alias MatchMaker.Collections
  alias MatchMaker.Collections.MatchAssignment

  describe "match_runner" do
    defp create_collection(attrs \\ %{}) do
      {:ok, collection} =
        attrs
        |> Enum.into(%{
          name: "Test collection",
          description: "desc",
          webhook_url: "https://example.com/webhook",
          webhook_template: "",
          cron_expression: "* * * * *",
          enabled: true
        })
        |> Collections.create_collection()

      collection
    end

    defp create_item(collection, side, attrs \\ %{}) do
      {:ok, item} =
        attrs
        |> Enum.into(%{
          name: "#{side} item",
          description: "item",
          side: side,
          collection_id: collection.id,
          enabled: true
        })
        |> Collections.create_item()

      item
    end

    defp collection_with_items(collection) do
      collection.id
      |> Collections.get_collection_with_items!()
      |> Map.put(:webhook_url, nil)
    end

    test "do not run with empty collection" do
      collection = create_collection()
      _right = create_item(collection, :right)

      collection = collection_with_items(collection)

      assert {:error, "Not enough people for a match"} = MatchRunner.run(collection)
    end

    test "do not run without tasks" do
      collection = create_collection()
      _left = create_item(collection, :left)

      collection = collection_with_items(collection)

      assert {:error, "Not enough tasks for a match"} = MatchRunner.run(collection)
    end

    test "a 1:1 match works" do
      collection = create_collection()
      left = create_item(collection, :left)
      right = create_item(collection, :right)

      collection = collection_with_items(collection)

      assert {:ok, match} = MatchRunner.run(collection)

      assignments =
        MatchAssignment
        |> where([ma], ma.match_id == ^match.id)
        |> Repo.all()

      assert [%MatchAssignment{left_item_id: left_id, right_item_id: right_id}] = assignments
      assert left_id == left.id
      assert right_id == right.id
    end

    test "distributes assignments across available left items" do
      collection = create_collection()
      left_one = create_item(collection, :left, %{name: "Left 1"})
      left_two = create_item(collection, :left, %{name: "Left 2"})
      Enum.each(1..3, fn idx -> create_item(collection, :right, %{name: "Task #{idx}"}) end)

      collection = collection_with_items(collection)

      assert {:ok, match} = MatchRunner.run(collection)

      assignments =
        MatchAssignment
        |> where([ma], ma.match_id == ^match.id)
        |> Repo.all()

      assigned_left_ids = assignments |> Enum.map(& &1.left_item_id) |> Enum.uniq() |> Enum.sort()

      assert length(assignments) == 3
      assert assigned_left_ids == Enum.sort([left_one.id, left_two.id])
    end

    test "ignores disabled participants and tasks" do
      collection = create_collection()
      active_left = create_item(collection, :left, %{name: "Active left"})
      _inactive_left = create_item(collection, :left, %{name: "Inactive left", enabled: false})
      active_right = create_item(collection, :right, %{name: "Active right"})
      _inactive_right = create_item(collection, :right, %{name: "Inactive right", enabled: false})

      collection = collection_with_items(collection)

      assert {:ok, match} = MatchRunner.run(collection)

      assignments =
        MatchAssignment
        |> where([ma], ma.match_id == ^match.id)
        |> Repo.all()

      assert [%MatchAssignment{left_item_id: left_id, right_item_id: right_id}] = assignments
      assert left_id == active_left.id
      assert right_id == active_right.id
    end

    test "returns validation error when a pair spans collections" do
      collection = create_collection(%{name: "Primary"})
      _left = create_item(collection, :left)
      _right = create_item(collection, :right)

      other_collection = create_collection(%{name: "Other"})
      rogue_left = create_item(other_collection, :left)

      collection =
        collection
        |> collection_with_items()
        |> Map.put(:left_items, [rogue_left])

      assert {:error, :mismatched_collections} = MatchRunner.run(collection)
    end
  end
end
