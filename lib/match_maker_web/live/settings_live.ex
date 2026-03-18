defmodule MatchMakerWeb.SettingsLive do
  use MatchMakerWeb, :live_view
  alias MatchMaker.Accounts

  on_mount {MatchMakerWeb.AuthController, :admin}

  @impl true
  def mount(_params, _session, socket) do
    users = Accounts.list_users()

    {:ok, socket
    |> assign(:section, :general)
    |> assign(users: users)}
  end

  @impl true
  def handle_event("switch", %{"section" => section}, socket) do
    {:noreply, assign(socket, :section, String.to_atom(section))}
  end


  def handle_event("change_role", %{"user_id" => id, "value" => role}, socket) do
    user = Accounts.get_user!(id)

    if user.role != role do
      case Accounts.update_user_role(user, role) do
        {:ok, user} ->
          {:noreply,
           socket
           |> put_flash(:info, "User updated successfully")
           |> assign(user: user, user_changeset: nil)}

        {:error, changeset} ->
          {:noreply, assign(socket, :user_changeset, changeset)}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({flash, level, msg}, socket) do
    {:noreply, put_flash(socket, level, msg)}
  end
end
