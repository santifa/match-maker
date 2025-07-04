defmodule MatchMakerWeb.CollectionFormComponent do
  use MatchMakerWeb, :live_component

  alias MatchMaker.Collections

  def update(assigns, socket) do
    changeset =
      assigns.collection
      |> Collections.change_collection()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.modal
        id="collection-modal"
        show={@show_modal}
        on_cancel={JS.push("close_modal")}
        title={@collection.name}
      >
        <.form_wrapper
          for={@changeset}
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
          :let={f}
        >
          <.text_field  field={f[:name]} label="Name" placeholder="Collection Name" required />
          <.text_field field={f[:description]} label="Description" placeholder="Description" />
          <.text_field field={f[:cron_expression]} label="Cron" placeholder="0 9 * * 1" />
          <.url_field field={f[:webhook_url]} label="Webhook URL" placeholder="https://example.com" />
          <.button class="mt-4" type="submit">Speichern</.button>
        </.form_wrapper>
      </.modal>
    </div>
    """
  end

  # <.text_field field={f[:webhook_template]} label="Webhook Template" placeholder="{ ... }" />

  def handle_event("validate", %{"collection" => params}, socket) do
    changeset =
      socket.assigns.collection
      |> Collections.change_collection(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"collection" => params}, socket) do
    save_collection(socket, socket.assigns.action, params)
  end

  defp save_collection(socket, :new, params) do
    case Collections.create_collection(params) do
      {:ok, collection} ->
        MatchMaker.Cron.register_cron_for_collection(collection)
        send(self(), :collection_saved)
        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_collection(socket, :edit, params) do
    case Collections.update_collection(socket.assigns.collection, params) do
      {:ok, collection} ->
        MatchMaker.Cron.refresh_cron_for_collection(collection)
        send(self(), :collection_saved)
        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
