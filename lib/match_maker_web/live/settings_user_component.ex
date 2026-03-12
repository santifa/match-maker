defmodule MatchMakerWeb.SettingsUserComponent do
  use MatchMakerWeb, :live_component

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(:user_changeset, nil)
     |> assign(assigns)
    }
  end

  def render(assigns) do
    ~H"""
    <div>
      <.h2>User Settings</.h2>
      <.p class="mb-4">See the sidebar for more settings</.p>

      <.table>
        <:header>Name</:header>
        <:header>Email</:header>
        <:header>Role</:header>
        <%= for user <- @users do %>
        <.tr>
          <.td>{user.name}</.td>
          <.td>{user.email}</.td>
          <.td>
            <%= if user.role == "admin" do %>
            <.native_select name="role" space="small" size="small"
            phx-click="change_role" phx-value-user_id={user.id}>
              <:option value="user">User</:option>
              <:option value="admin" selected>Admin</:option>
            </.native_select>
            <% else %>
            <.native_select name="role" space="small" size="small"
            phx-click="change_role" phx-value-user_id={user.id}>
              <:option value="user" selected>User</:option>
              <:option value="admin">Admin</:option>
            </.native_select>
            <% end %>
          </.td>
        </.tr>
        <% end %>
      </.table>

    </div>
    """
  end
end
