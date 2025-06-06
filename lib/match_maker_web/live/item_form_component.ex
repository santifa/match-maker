defmodule MatchMakerWeb.ItemFormComponent do
  use MatchMakerWeb, :live_component

  alias MatchMaker.Collections
  alias MatchMaker.Collections.Item

  def update(assigns, socket) do
    item =
      cond do
        assigns[:item] -> assigns.item
        assigns[:force_side] -> %Item{collection_id: assigns.collection_id, side: assigns.force_side}
        true -> %Item{collection_id: assigns.collection_id}
      end
    # item = Map.get(assigns, :item, %Item{collection_id: assigns.collection_id})
    # item = assigns[:item] || %Item{collection_id: assigns.collection_id}
    changeset = Collections.change_item(item)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:item, item)
     |> assign(:changeset, changeset)}
  end

def render(assigns) do
  ~H"""
  <tr>
    <td colspan="3">
      <.form
        for={@changeset}
        as={:item}
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
        :let={f}
      >
        <div class="flex gap-2 items-center">
          <.input field={f[:name]} type="text" label="Name" />
          <.input field={f[:description]} type="text" label="Beschreibung" />
          <.input type="hidden" field={f[:collection_id]} value={@collection_id} />
          <%= if assigns[:force_side] do %>
          <.input type="hidden" field={f[:side]} value={@force_side} />
          <% end %>
          <.button class="ml-2">💾</.button>
          <.link phx-click="cancel"  phx-target={@myself}>Abbrechen</.link>
        </div>
      </.form>
    </td>
  </tr>
  """
end

  def handle_event("validate", %{"item" => params}, socket) do
    changeset =
      %Item{}
      |> Collections.change_item(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("save", %{"item" => params}, socket) do
    case socket.assigns.item do
      %Item{id: nil} -> create(params, socket)
      %Item{} = item -> update_item(item, params, socket)
    end
  end

  def handle_event("cancel", _params, socket) do
    send(self(), {:cancel, socket.assigns.item})
    {:noreply, socket}
  end

  defp create(params, socket) do
    case Collections.create_item(params) do
      {:ok, _item} ->
        send(self(), :item_saved)
        {:noreply, reset_form(socket)}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp update_item(item, params, socket) do
    case Collections.update_item(item, params) do
      {:ok, _item} ->
        send(self(), :item_saved)
        {:noreply, reset_form(socket)}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp reset_form(socket) do
    changeset = Collections.change_item(%Item{collection_id: socket.assigns.collection_id})
    socket
    |> assign(:item, %Item{})
    |> assign(:changeset, changeset)
  end

end
