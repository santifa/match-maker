defmodule MatchMaker.Repo.Migrations.AddCollectionEnabledFlag do
  use Ecto.Migration

  def change do
    alter table(:collections) do
      add :enabled, :boolean, default: true, null: false
    end
  end
end
