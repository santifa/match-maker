defmodule MatchMaker.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :google_uid, :string, null: false
      add :name, :string
      add :role, :string, null: false, default: "user"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:google_uid])
  end
end
