defmodule MatchMaker.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  users with different roles.

  The fixtures are stored in the database and should
  be used to setup the database for testing purposes.
  """

  alias MatchMaker.Accounts

  @account_attrs %{info: %{name: "Test user"}, role: "user"}

  def unique_email(domain \\ "example.com"), do: "user#{System.unique_integer()}@#{domain}"
  def unique_id, do: "uid-#{System.unique_integer()}"

  def user_fixture(attrs \\ %{}) do
    attrs = Map.merge(unique_account_attrs(), attrs)
    {:ok, account} = Accounts.get_or_create_user_from_google(attrs)
    account
  end

  def admin_fixture(attrs \\ %{}) do
    attrs
    |> Map.put(:role, "admin")
    |> user_fixture()
  end

  defp unique_account_attrs do
    info = @account_attrs.info |> Map.put(:email, unique_email())

    @account_attrs
    |> Map.put(:info, info)
    |> Map.put(:uid, unique_id())
  end
end
