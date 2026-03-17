defmodule MatchMaker.AccountsTest do
  use MatchMaker.DataCase, async: true

  alias MatchMaker.Accounts
  alias MatchMaker.Accounts.User

  setup do
    Application.put_env(:match_maker, :allowed_domains, ["example.com"])
    :ok
  end

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
    assert {:error, :invalid_domain} =
             Accounts.get_or_create_user_from_google(auth_fixture("a@test.com"))
  end

  test "get_or_create_user_from_google inserts the first user as admin" do
    assert {:ok, %User{} = user} = Accounts.get_or_create_user_from_google(auth_fixture())
    assert user.role == "admin"
  end

  test "update_user_role updates the role" do
    {:ok, %User{} = user} = Accounts.get_or_create_user_from_google(auth_fixture("b@example.com", "uid-3"))
    assert user.role == "admin"

    assert {:ok, %User{} = updated} = Accounts.update_user_role(user, "user")
    assert updated.role == "user"
  end

  test "get_or_create_user_from_google returns existing user by google uid" do
    {:ok, %User{id: id} = user} = Accounts.get_or_create_user_from_google(auth_fixture())
    assert {:ok, %User{id: ^id}} = Accounts.get_or_create_user_from_google(auth_fixture("user@example.com", user.google_uid))
  end

  test "subsequent users are created with role user" do
    assert {:ok, %User{role: "admin"}} = Accounts.get_or_create_user_from_google(auth_fixture("first@example.com", "uid-1"))
    assert {:ok, %User{role: "user"}} = Accounts.get_or_create_user_from_google(auth_fixture("second@example.com", "uid-2"))
  end

  test "update_user_role rejects invalid role" do
    {:ok, user} = Accounts.get_or_create_user_from_google(auth_fixture("role@example.com", "uid-role"))
    assert {:error, %Ecto.Changeset{} = changeset} = Accounts.update_user_role(user, "invalid")
    assert %{role: ["is invalid"]} = errors_on(changeset)
  end

  test "change_user downcases email" do
    {:ok, user} = Accounts.get_or_create_user_from_google(auth_fixture("MIXED@example.com", "uid-mixed"))
    assert user.email == "mixed@example.com"
  end

  test "is_admin? returns expected booleans" do
    {:ok, admin} = Accounts.get_or_create_user_from_google(auth_fixture("admin@example.com", "uid-admin"))
    {:ok, user} = Accounts.get_or_create_user_from_google(auth_fixture("user@example.com", "uid-user"))

    assert Accounts.is_admin?(nil) == false
    assert Accounts.is_admin?(user) == false
    assert Accounts.is_admin?(admin) == true

    {:ok, user} = Accounts.update_user_role(user, "admin")
    assert Accounts.is_admin?(user) == true
  end
end
