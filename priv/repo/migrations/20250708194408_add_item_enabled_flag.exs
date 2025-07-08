defmodule MatchMaker.Repo.Migrations.AddItemEnabledFlag do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :enabled, :boolean, default: true
    end
  end
end
