defmodule MatchMaker.Repo.Migrations.CreateMatchAssignments do
  use Ecto.Migration

  def change do
    create table(:match_assignments) do
      add :match_id, references(:matches, on_delete: :delete_all), null: false
      add :right_item_id, references(:items, on_delete: :delete_all), null: false
      add :left_item_id, references(:items, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:match_assignments, [:match_id])
    create index(:match_assignments, [:right_item_id])
    create index(:match_assignments, [:left_item_id])
  end
end
