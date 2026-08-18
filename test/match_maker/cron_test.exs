defmodule MatchMaker.CronTest do
  use MatchMaker.DataCase

  alias MatchMaker.Collections
  alias MatchMaker.Cron

  import MatchMaker.CollectionsFixtures

  test "cron runs use the collection matching algorithm" do
    collection = collection_fixture(%{matching_algorithm: :greedy_history_aware})
    left_one = item_fixture(collection, %{side: :left})
    left_two = item_fixture(collection, %{side: :left})
    right_one = item_fixture(collection, %{side: :right})
    right_two = item_fixture(collection, %{side: :right})

    assert {:ok, _} = Collections.create_match(collection, [{right_one.id, left_one.id}])
    assert {:ok, _} = Collections.create_match(collection, [{right_two.id, left_two.id}])

    assert {:ok, _match} = Cron.run_job(collection)
  end
end
