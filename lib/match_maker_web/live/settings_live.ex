defmodule MatchMakerWeb.SettingsLive do
  use MatchMakerWeb, :live_view
  alias MatchMaker.Accounts

  @impl true
  def mount(_params, session, socket) do
    user = Map.get(session, "current_user")

    case is_admin?(user) do
      false -> redirect(socket, to: ~p"/dashboard")
      true ->
        users = Accounts.list_users()

        {:ok, socket
        |> assign(:current_user, user)
        |> assign(:section, :general)
        |> assign(users: users)
        }
    end
  end

  defp is_admin?(nil), do: false
  defp is_admin?(user), do: user.role == "admin"

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
end
