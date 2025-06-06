defmodule MatchMaker.Repo.Migrations.CreateCollections do
  use Ecto.Migration

  def change do
    create table(:collections) do
      add :name, :string
      add :description, :text
      add :webhook_url, :string
      add :webhook_template, :text

      timestamps(type: :utc_datetime)
    end
  end
end
