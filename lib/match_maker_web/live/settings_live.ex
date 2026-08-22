defmodule MatchMakerWeb.SettingsLive do
  alias MatchMaker.Collections
  use MatchMakerWeb, :live_view
  alias MatchMaker.Accounts

  on_mount {MatchMakerWeb.AuthController, :admin}

  @impl true
  def mount(_params, _session, socket) do
    users = Accounts.list_users()

    {:ok,
     socket
     |> assign(users: users)
     |> allow_upload(:file,
                     accept: ~w(.json),
                     max_entries: 1,
                     max_file_size: 5_000_000
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-w-full m-8">
      <.h2>General Settings</.h2>

      <.tabs id="import-export" rounded="medium" gap="large" class="max-w-2xl mt-4">
        <:tab class="text-black" icon="hero-arrow-down">Export</:tab>
        <:tab class="text-black" icon="hero-arrow-up">Import</:tab>
        <:tab class="text-black" icon="hero-user">user</:tab>

        <:panel>
          <.button>
            <.link title="Export Collection" target="_blank" navigate={~p"/collections/export/json"}>
              Export Collections
            </.link>
          </.button>
        </:panel>

        <:panel class="max-w-md">
          <form id="upload-form" phx-change="validate" phx-submit="import">
            <.live_file_input upload={@uploads.file} class="text-gray-900" />
            <.button class="mt-2" type="submit">Import Collections</.button>
          </form>
        </:panel>

        <:panel>
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
                <.native_select
                  id="role-admin-#{user.id}"
                  name="role"
                  space="small"
                  size="small"
                  phx-click="change_role"
                  phx-value-user_id={user.id}
                >
                  <:option value="user">User</:option>
                  <:option value="admin" selected>Admin</:option>
                </.native_select>
                <% else %>
                <.native_select
                  id="role-user-#{user.id}"
                  name="role"
                  space="small"
                  size="small"
                  phx-click="change_role"
                  phx-value-user_id={user.id}
                >
                  <:option value="user" selected>User</:option>
                  <:option value="admin">Admin</:option>
                </.native_select>
                <% end %>
              </.td>
            </.tr>
            <% end %>
          </.table>
        </:panel>
      </.tabs>
    </div>
    """
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("import", _params, socket) do
    result =
      consume_uploaded_entries(socket, :file, fn %{path: path}, _entry ->
        case Collections.import_from_json(path) do
          {:ok, _} = ok -> {:ok, ok}
          {:error, _} = err -> {:postpone, err}
        end
      end)
      |> List.first()

    case result do
      {:ok, _} ->
        {:noreply, put_flash(socket, :info, "Successfully uploaded file")}

      {:error, err} ->
        case err do
          {:invalid, changeset} ->
            error = changeset.errors |> List.first() |> elem(1) |> elem(0)
            {:noreply, put_flash(socket, :error, "Failed to upload file: #{error}")}

          _ ->
            {:noreply, put_flash(socket, :error, "Failed to upload file: #{err}")}
        end
    end
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
end
