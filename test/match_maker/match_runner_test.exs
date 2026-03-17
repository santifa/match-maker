defmodule MatchMaker.MatchRunnerTest do
  use MatchMaker.DataCase

  alias MatchMaker.MatchRunner
  alias MatchMaker.Collections
  alias MatchMaker.Collections.MatchAssignment

  describe "match_runner" do
    import MatchMaker.CollectionsFixtures

    defp collection_with_items(collection) do
      collection.id
      |> Collections.get_collection_with_items!()
      |> Map.put(:webhook_url, nil)
    end

    test "do not run with empty collection" do
      collection = collection_fixture()
      _right = item_fixture(collection, %{side: :right})

      collection = collection_with_items(collection)

      assert {:error, "Not enough people for a match"} = MatchRunner.run(collection)
    end

    test "do not run without tasks" do
      collection = collection_fixture()
      _left = item_fixture(collection, %{side: :left})

      collection = collection_with_items(collection)

      assert {:error, "Not enough tasks for a match"} = MatchRunner.run(collection)
    end

    test "a 1:1 match works" do
      collection = collection_fixture()
      left = item_fixture(collection, %{side: :left})
      right = item_fixture(collection, %{side: :right})

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
      collection = collection_fixture()
      left_one = item_fixture(collection, %{name: "Left 1", side: :left})
      left_two = item_fixture(collection, %{name: "Left 2", side: :left})
      Enum.each(1..3, fn idx -> item_fixture(collection, %{name: "Task #{idx}", side: :right}) end)

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
      collection = collection_fixture()
      active_left = item_fixture(collection, %{name: "Active left", side: :left})
      _inactive_left = item_fixture(collection, %{name: "Inactive left", enabled: false, side: :left})
      active_right = item_fixture(collection,  %{name: "Active right", side: :right})
      _inactive_right = item_fixture(collection, %{name: "Inactive right", enabled: false, side: :right})

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
      collection = collection_fixture(%{name: "Primary"})
      _left = item_fixture(collection, %{side: :left})
      _right = item_fixture(collection, %{side: :right})

      other_collection = collection_fixture(%{name: "Other"})
      rogue_left = item_fixture(other_collection, %{side: :left})

      collection =
        collection
        |> collection_with_items()
        |> Map.put(:left_items, [rogue_left])

      assert {:error, :mismatched_collections} = MatchRunner.run(collection)
    end

    test "skips webhook when url is blank" do
      collection = collection_fixture(%{webhook_url: ""})
      _left = item_fixture(collection, %{side: :left})
      _right = item_fixture(collection, %{side: :right})

      collection = Collections.get_collection_with_items!(collection.id)

      # Should not attempt an HTTP request and still succeed
      assert {:ok, _match} = MatchRunner.run(collection)
    end
  end
end
