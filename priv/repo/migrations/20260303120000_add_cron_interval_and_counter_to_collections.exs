defmodule MatchMaker.Repo.Migrations.AddCronIntervalAndCounterToCollections do
  use Ecto.Migration

  def change do
    alter table(:collections) do
      add :cron_interval, :integer, null: false, default: 0
      add :cron_counter, :integer, null: false, default: 0
    end

  end
end
