defmodule MatchMaker.Repo.Migrations.AddCronToCollections do
  use Ecto.Migration

  def change do
    alter table(:collections) do
      add :cron_expression, :string
      add :last_matched_at, :utc_datetime_usec
    end
  end
end
