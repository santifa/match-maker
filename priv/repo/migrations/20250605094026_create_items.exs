defmodule MatchMaker.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :name, :string
      add :description, :text
      add :side, :string, null: false
      add :collection_id, references(:collections, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:items, [:collection_id])
  end
end
