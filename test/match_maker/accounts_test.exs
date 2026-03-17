defmodule MatchMaker.AccountsTest do
  use MatchMaker.DataCase, async: true

  alias MatchMaker.Accounts
  alias MatchMaker.Accounts.User

  defp auth_fixture(email \\ "user@example.com", uid \\ "uid-123", name \\ "Test User") do
    %{
      uid: uid,
      info: %{
        email: email,
        name: name
      }
    }
  end

  test "get_or_create_user_from_google fails without email" do
    assert {:error, :missing_email} =
             Accounts.get_or_create_user_from_google(%{uid: "uid-2", info: %{}})
  end

  test "get_or_create_user_from_google fails with invalid email" do
    Application.put_env(:match_maker, :allowed_domains, ["example.com"])
    assert {:error, :invalid_domain} =
             Accounts.get_or_create_user_from_google(auth_fixture("a@test.com"))
  end

  test "get_or_create_user_from_google inserts the first user as admin" do
    Application.put_env(:match_maker, :allowed_domains, ["example.com"])
    assert {:ok, %User{} = user} = Accounts.get_or_create_user_from_google(auth_fixture())
    assert user.role == "admin"
  end

  test "update_user_role updates the role" do
    Application.put_env(:match_maker, :allowed_domains, ["example.com"])
    {:ok, %User{} = user} = Accounts.get_or_create_user_from_google(auth_fixture("b@example.com", "uid-3"))
    assert user.role == "admin"

    assert {:ok, %User{} = updated} = Accounts.update_user_role(user, "user")
    assert updated.role == "user"
  end
end
