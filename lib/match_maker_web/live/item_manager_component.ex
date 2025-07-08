defmodule MatchMakerWeb.ItemManagerComponent do
  use MatchMakerWeb, :live_component
  alias MatchMaker.Collections

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:left_items, assigns.collection.left_items)
     |> assign(:right_items, assigns.collection.right_items)
     |> assign(:editing_changeset, nil)
     |> assign(:editing_item, nil)
     |> assign(:new_item_side, nil)
     |> assign(:new_changeset, nil)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.modal
        id="item-manager-modal"
        rounded="large"
        padding="large"
        size="quadruple_large"
        class="max-w-4xl w-4xl"
        show={@show_item_modal}
        on_cancel={JS.push("close_item_modal")}
        title={"Items verwalten für: #{@collection.name}"}
      >
        <div class="grid grid-cols-2 gap-6">
          <div>
            <.h4 class="mb-4">Personen</.h4>
            <.item_table
              items={@left_items}
              side={:left}
              editing_item={@editing_item}
              editing_changeset={@editing_changeset}
              new_item_side={@new_item_side}
              new_changeset={@new_changeset}
              collection_id={@collection.id}
              myself={@myself}
            />
          </div>

          <div>
            <.h4 class="mb-4">Tasks</.h4>
            <.item_table
              items={@right_items}
              side={:right}
              editing_item={@editing_item}
              editing_changeset={@editing_changeset}
              new_item_side={@new_item_side}
              new_changeset={@new_changeset}
              collection_id={@collection.id}
              myself={@myself}
            />
          </div>
        </div>

        <div class="grid grid-cols-2 gap-6 mt-4">
          <.button
            phx-click="new_item"
            phx-value-side="left"
            phx-target={@myself}
            full_width={true}
            variant="subtle"
            color="misc"
          >
            Neu
          </.button>
          <.button
            phx-click="new_item"
            phx-value-side="right"
            phx-target={@myself}
            full_width={true}
            variant="subtle"
            color="misc"
          >
            Neu
          </.button>
        </div>
      </.modal>
    </div>
    """
  end

  attr :items, :any
  attr :side, :atom
  attr :editing_item, :any
  attr :editing_changeset, :any
  attr :new_item_side, :any
  attr :new_changeset, :any
  attr :collection_id, :any
  attr :myself, :any

  def item_table(assigns) do
    ~H"""
    <.table header_border="extra_small" rows_border="extra_small" cols_border="extra_small" table_fixed="true">
      <:header>Name</:header>
      <:header>Active</:header>
      <:header>Actions</:header>

      <%= for item <- @items do %>
        <.tr>
          <.td>
            <%= if item.description do %>
            <.tooltip text={item.description} position="right">
            {item.name}
            </.tooltip>
            <% else %>
            {item.name}
            <% end %>
          </.td>

          <.td>
            <%= if item.enabled do %>
            <.button
              phx-click="toggle_item_enabled"
              phx-value-id={item.id}
              phx-target={@myself}
              size="extra_small"
              font_weight="font-light"
              icon="hero-check"
            />
            <% else %>
            <.button
              phx-click="toggle_item_enabled"
              phx-value-id={item.id}
              phx-target={@myself}
              size="extra_small"
              font_weight="font-light"
              icon="hero-x-mark"
            />
            <% end %>

          </.td>
          <.td>
            <.button_group color="secondary" class="outline-thin">
              <.button
                phx-click="edit_item"
                phx-value-id={item.id}
                phx-target={@myself}
                icon="hero-pencil-square"
                size="extra_small"
                font_weight="font-light"
              >
              </.button>
              <.button
                phx-click="delete_item"
                phx-value-id={item.id}
                phx-target={@myself}
                icon="hero-trash"
                size="extra_small"
                font_weight="font-light"
              >
              </.button>
            </.button_group>
          </.td>
        </.tr>

        <%= if @editing_item && @editing_item.id == item.id do %>
          <.tr>
            <.td colspan="3">Item bearbeiten</.td>
          </.tr>
          <.form_wrapper
            :let={f}
            for={@editing_changeset}
            phx-submit="update_item"
            phx-target={@myself}
            class="mt-4"
          >
            <.tr>
              <.td>
                <.text_field label="Name" field={f[:name]} placeholder="Name" />
              </.td>
              <.td>
                <.text_field label="Description" field={f[:description]} placeholder="Description" />
              </.td>
              <.td>
                <.input type="hidden" field={f[:id]} />
                <.button_group>
                  <.button icon="hero-plus-circle" size="extra_small" font_weight="font-light">
                  </.button>
                  <.button
                    phx-click="abort_form"
                    phx-target={@myself}
                    icon="hero-x-mark"
                    size="extra_small"
                    font_weight="font-light"
                  >
                  </.button>
                </.button_group>
              </.td>
            </.tr>
          </.form_wrapper>
        <% end %>
      <% end %>
    </.table>

    <%= if @new_item_side == @side do %>
      <.form_wrapper
        :let={f}
        for={@new_changeset}
        phx-submit="save_item"
        phx-target={@myself}
        class="mt-4"
      >
        <div class="grid grid-cols-2 gap-4">
          <.text_field label="Name" field={f[:name]} placeholder="Name" />
          <.text_field label="Description" field={f[:description]} placeholder="Description" />
        </div>
        <.input type="hidden" field={f[:side]} value={@side} />
        <.input type="hidden" field={f[:enabled]} value="true" />
        <.input type="hidden" field={f[:collection_id]} value={@collection_id} />
        <div class="mt-4">
          <.button icon="hero-plus-circle"></.button>
          <.button phx-click="abort_form" phx-target={@myself} icon="hero-x-mark"></.button>
        </div>
      </.form_wrapper>
    <% end %>
    """
  end

  def handle_event("new_item", %{"side" => side}, socket) do
    changeset =
      %Collections.Item{collection_id: socket.assigns.collection.id, side: String.to_atom(side)}
      |> Collections.change_item()

    {:noreply,
     socket
     |> assign(:new_item_side, String.to_atom(side))
     |> assign(:new_changeset, changeset)
     |> assign(:editing_item, nil)}
  end

  def handle_event("edit_item", %{"id" => id}, socket) do
    item = Collections.get_item!(id)

    {:noreply,
     socket
     |> assign(:editing_item, item)
     |> assign(:editing_changeset, Collections.change_item(item))
     |> assign(:new_item_side, nil)}
  end

  def handle_event("save_item", %{"item" => item_params}, socket) do
    case Collections.create_item(item_params) do
      {:ok, _item} ->
        send(self(), {:reload_collection, socket.assigns.collection.id})
        reload_collection(socket.assigns.collection.id, socket)

      {:error, changeset} ->
        IO.inspect(changeset)
        {:noreply, assign(socket, :new_changeset, changeset)}
    end
  end

  def handle_event("update_item", %{"item" => item_params}, socket) do
    item = Collections.get_item!(item_params["id"])

    case Collections.update_item(item, item_params) do
      {:ok, _item} ->
        reload_collection(socket.assigns.collection.id, socket)

      {:error, changeset} ->
        {:noreply, assign(socket, :editing_changeset, changeset)}
    end
  end

  def handle_event("delete_item", %{"id" => id}, socket) do
    item = Collections.get_item!(id)
    {:ok, _} = Collections.delete_item(item)

    collection = Collections.get_collection_with_items!(socket.assigns.collection.id)
    send(self(), {:reload_collection, socket.assigns.collection.id})

    {:noreply,
     socket
     |> assign(:collection, collection)
     |> assign(:left_items, collection.left_items)
     |> assign(:right_items, collection.right_items)
     |> assign(:editing_item, nil)}
  end

  def handle_event("toggle_item_enabled", %{"id" => id}, socket) do
    item = Collections.get_item!(id)

    case Collections.update_item(item, %{"enabled" => !item.enabled}) do
      {:ok, _item} ->
        reload_collection(socket.assigns.collection.id, socket)
      {:error, changeset} ->
        {:noreply, assign(socket, :editing_changeset, changeset)}
    end
  end

  def handle_event("abort_form", _, socket) do
    reload_collection(socket.assigns.collection.id, socket)
  end

  defp reload_collection(id, socket) do
    collection = Collections.get_collection_with_items!(id)

    {:noreply,
     socket
     |> assign(:collection, collection)
     |> assign(:left_items, collection.left_items)
     |> assign(:right_items, collection.right_items)
     |> assign(:new_item_side, nil)
     |> assign(:editing_item, nil)}
  end
end
