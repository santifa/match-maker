defmodule MatchMakerWeb.SettingsLive do
  use MatchMakerWeb, :live_view
  alias MatchMaker.Accounts

  on_mount {MatchMakerWeb.AuthController, :admin}

  @impl true
  def mount(_params, _session, socket) do
    users = Accounts.list_users()

    {:ok, socket
    |> assign(users: users)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.flex justify="start" class="m-8">
      <.tabs id="settings" size="large" rounded="small" gap="small" vertical>
        <:tab icon="hero-cog-6-tooth">general</:tab>
        <:tab icon="hero-user">user</:tab>

        <:panel>
          <.live_component module={MatchMakerWeb.SettingsGeneralComponent}
            id="general" user_id={@current_user.id} />
        </:panel>
        <:panel>
          <.live_component module={MatchMakerWeb.SettingsUserComponent}
            id="user" users={@users} />
        </:panel>
      </.tabs>
    </.flex>
    """
  end

  @impl true
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
  def handle_info({_flash, level, msg}, socket) do
    {:noreply, put_flash(socket, level, msg)}
  end
end
