defmodule MatchMakerWeb.CollectionLive.FormComponent do
  use MatchMakerWeb, :live_component

  alias MatchMaker.Collections

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage collection records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="collection-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:webhook_url]} type="text" label="Webhook url" />
        <.input field={@form[:webhook_template]} type="text" label="Webhook template" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Collection</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{collection: collection} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Collections.change_collection(collection))
     end)}
  end

  @impl true
  def handle_event("validate", %{"collection" => collection_params}, socket) do
    changeset = Collections.change_collection(socket.assigns.collection, collection_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"collection" => collection_params}, socket) do
    save_collection(socket, socket.assigns.action, collection_params)
  end

  defp save_collection(socket, :edit, collection_params) do
    case Collections.update_collection(socket.assigns.collection, collection_params) do
      {:ok, collection} ->
        notify_parent({:saved, collection})

        {:noreply,
         socket
         |> put_flash(:info, "Collection updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_collection(socket, :new, collection_params) do
    case Collections.create_collection(collection_params) do
      {:ok, collection} ->
        notify_parent({:saved, collection})

        {:noreply,
         socket
         |> put_flash(:info, "Collection created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
