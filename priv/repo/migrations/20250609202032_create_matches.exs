defmodule MatchMaker.Repo.Migrations.CreateMatches do
  use Ecto.Migration

  def change do
    create table(:matches) do
      add :collection_id, references(:collections, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:matches, [:collection_id])
  end
end
