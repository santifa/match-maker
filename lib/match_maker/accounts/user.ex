defmodule MatchMaker.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :google_uid, :string
    field :name, :string
    field :role, :string, default: "user"

    timestamps(type: :utc_datetime)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :google_uid, :name, :role])
    |> update_change(:email, fn email -> email |> String.downcase end)
    |> validate_required([:email, :google_uid, :role])
    |> validate_format(:email, ~r/^[^@\s]+@[^@\s]+$/)
    |> validate_inclusion(:role, ["user", "admin"])
    |> unique_constraint(:email, name: :users_lower_email_index)
    |> unique_constraint(:google_uid)
  end
end
