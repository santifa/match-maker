defmodule MatchMaker.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias MatchMaker.Repo

  alias MatchMaker.Accounts.User

  def list_users do
    Repo.all(User)
  end

  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  def get_user_by_google_uid(uid) when is_binary(uid) do
    Repo.get_by(User, google_uid: uid)
  end

  def get_or_create_user_from_google(auth) do
    google_uid = to_string(auth.uid)

    case get_user_by_google_uid(google_uid) do
      %User{} = user ->
        {:ok, user}
      nil ->
        # Create a new user
        with {:ok, mail} <- fetch_email(auth),
             {:ok, mail} <- allowed_email(mail) do
          upsert_user(%{email: mail, name: fetch_name(auth), google_uid: google_uid})
        else
          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  def update_user_role(user, role) do
    user
    |> change_user(%{"role" => role})
    |> Repo.update()
  end

  defp upsert_user(params) do
    case get_user_by_google_uid(params.google_uid) do
      nil ->
        role = if first_user?(), do: "admin", else: "user"

        %User{role: role}
        |> User.changeset(params)
        |> Repo.insert()

      %User{} = user ->
        user
        |> User.changeset(params)
        |> Repo.update()
    end
  end

  defp first_user?, do: Repo.aggregate(User, :count, :id) == 0

  defp fetch_email(%{info: %{email: email}}) when is_binary(email) and email != "" do
    {:ok, email}
  end

  defp fetch_email(_), do: {:error, :missing_email}

  defp fetch_name(%{info: %{name: name}}) when is_binary(name) and name != "" do
    name
  end

  defp fetch_name(_), do: nil

  defp allowed_email(mail) do
    allowed_emails = Application.fetch_env!(:match_maker, :allowed_domains)

    mail_domain = mail |> String.split("@") |> List.last
    case Enum.member?(allowed_emails, mail_domain) do
      true -> {:ok, mail}
      false -> {:error, :invalid_domain}
    end
  end

  def is_admin?(nil), do: false
  def is_admin?(user), do: user.role == "admin"

  def is_user?(nil), do: false
  def is_user?(user) do
    case Repo.get(User, user.id) do
      %User{} = _ -> true
      _ -> false
    end
  end
end
