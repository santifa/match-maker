defmodule MatchMaker.Repo.Migrations.AddPairHistoryIndex do
  use Ecto.Migration

  def change do
    create index(:match_assignments, [:left_item_id, :right_item_id])
  end
end
