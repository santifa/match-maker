defmodule MatchMakerWeb.AuthController do
  @moduledoc """
  The auth controller handles user session related functionality.

  It offers registration through Uberauth and checks in `on_mount`
  if the user is allowed to visit liveview sites.
  """
  use MatchMakerWeb, :controller

  plug Ueberauth

  alias Phoenix.LiveView

  alias Ueberauth.Strategy.Helpers
  alias MatchMaker.Accounts


  @doc """
  The live view callback handler for managing user sessions.

  If the `current_user` assign is set in the session the user is authenticated.

  If the first definition is not matched than the user isn't authenticated and
  should be redirected to the start page.
  """
  def on_mount(:user, _params, %{"current_user" => user} = _session, socket) do
    if Accounts.is_user?(user) do
      # Populate the current user information towards the socket
      socket = Phoenix.Component.assign(socket, :current_user, user)
      {:cont, socket}
    else
      {:halt, redirect_require_login(socket)}
    end
  end

  def on_mount(:user, _params, _session, socket) do
    {:halt, redirect_require_login(socket)}
  end

  def on_mount(:admin, _params, %{"current_user" => user} = _session, socket) do
    case Accounts.is_admin?(user) do
      true ->
        Phoenix.Component.assign(socket, :current_user, user)
        {:cont, socket}
      false -> {:halt, redirect_require_login(socket)}
    end
  end

  defp redirect_require_login(socket) do
    socket
    |> LiveView.put_flash(:error, "Please sign in")
    |> LiveView.redirect(to: ~p"/")
  end

  @doc """
  The auth controller part handles OAuth requests.
  There is no view or other HTML connected to the controller as
  this is carried out by Uberauth and the OAuth providers
  """
  def request(conn, _params) do
    render(conn, :request, callback_url: Helpers.callback_url(conn))
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "You have been logged out!")
    |> clear_session()
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Accounts.get_or_create_user_from_google(auth) do
      {:ok, user} ->
        conn
        |> configure_session(renew: true)
        |> clear_session()
        # Make the user accessible to the templates and components
        |> put_session(:current_user, user)
        |> put_flash(:info, "Successfully authenticated.")
        |> redirect(to: "/dashboard")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to login: #{reason}")
        |> redirect(to: "/")
    end
  end
end
