defmodule MatchMaker.Repo.Migrations.UpdateUsersConstraints do
  use Ecto.Migration

  def up do
    execute("UPDATE users SET role = 'user' WHERE role IS NULL")
    execute("UPDATE users SET email = lower(email) WHERE email IS NOT NULL")
  end

  def change do
    alter table(:users) do
      modify :email, :string, null: false
      modify :google_uid, :string, null: false
      modify :role, :string, default: "user", null: false
    end

    create unique_index(:users, ["lower(email)"], name: :users_lower_email_index)
    create unique_index(:users, [:google_uid])
    create constraint(:users, [], name: :users_role_allowed, check: "role in ('admin', 'user')")
  end

  def down do
    drop_if_exists constraint(:users, :users_role_allowed)
    drop_if_exists index(:users, [:google_uid])
    drop_if_exists index(:users, [], name: :user_lower_email_index)
  end

end
