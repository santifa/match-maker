defmodule MatchMaker.Repo.Migrations.CreateCollections do
  use Ecto.Migration

  def change do
    create table(:collections) do
      add :name, :string
      add :description, :text
      add :webhook_url, :string, null: true
      add :webhook_template, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:collections, [:name])
  end
end
