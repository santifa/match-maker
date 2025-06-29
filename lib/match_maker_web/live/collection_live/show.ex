defmodule MatchMakerWeb.CollectionLive.Show do
  use MatchMakerWeb, :live_view

  alias MatchMaker.Collections
  alias MatchMaker.Collections.Item
  alias MatchMaker.MatchRunner

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    collection = Collections.get_collection_with_items!(id)
    changeset = Collections.change_collection(collection)

    last_match = Collections.get_last_match_with_assignments(collection.id)
    matches = Collections.list_matches_with_assignments(collection.id)

    {:ok,
     socket
     |> assign(:collection, collection)
     |> assign(:live_action, :show)
     |> assign(:editing_item_id, nil)
     |> assign(:new_item_side, nil)
     |> assign(:editing_collection, false)
     |> assign(collection_changeset: changeset)
     |> assign(last_match: last_match)
     |> assign(matches: matches)}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:collection, Collections.get_collection_with_items!(id))}
  end

  @impl true
  def handle_event("edit_collection", _params, socket) do
    {:noreply, assign(socket, editing_collection: true, live_action: :edit)}
  end

  @impl true
  def handle_event("cancel_edit_collection", _params, socket) do
    {:noreply, assign(socket, editing_collection: false)}
  end

  @impl true
  def handle_event("validate_collection", %{"collection" => params}, socket) do
    changeset =
      socket.assigns.collection
      |> Collections.change_collection(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, collection_changeset: changeset)}
  end

  @impl true
  def handle_event("save_collection", %{"collection" => params}, socket) do
    case Collections.update_collection(socket.assigns.collection, params) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> put_flash(:info, "Collection gespeichert.")
         |> assign(collection: updated)
         |> assign(editing_collection: false)
         |> assign(collection_changeset: Collections.change_collection(updated))}

      {:error, changeset} ->
        {:noreply, assign(socket, collection_changeset: changeset)}
    end
  end

  def handle_event("call_match_runner", _params, socket) do
  # Optional: sicherstellen, dass Items geladen sind
  collection =
    Collections.get_collection_with_items!(socket.assigns.collection.id)

    case MatchRunner.run(collection) do
      {:ok, _match} ->
        {:noreply,
         socket
         |> put_flash(:info, "Matching erfolgreich erstellt.")}

      {:error, :mismatched_collections} ->
        {:noreply, put_flash(socket, :error, "Left und Right Items gehören nicht zur gleichen Collection.")}

      {:error, :not_part_of_match_collection} ->
        {:noreply, put_flash(socket, :error, "Mindestens ein Item gehört nicht zur aktuellen Collection.")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Unbekannter Fehler: #{inspect(reason)}")}
    end
  end

  #
  # Handle items inline
  #
  @impl true
  def handle_event("new_item", %{"side" => side}, socket) do
    {:noreply, assign(socket, new_item_side: String.to_existing_atom(side))}
  end

  @impl true
  def handle_event("edit_item", %{"id" => id}, socket) do
    {:noreply, assign(socket, editing_item_id: String.to_integer(id))}
  end

  @impl true
  def handle_event("delete_item", %{"id" => id}, socket) do
    item = Collections.get_item!(id)
    {:ok, _} = Collections.delete_item(item)

    collection = Collections.get_collection_with_items!(socket.assigns.collection.id)

    {:noreply, assign(socket, collection: collection)}
  end

  def handle_info({:cancel, %Item{id: nil}}, socket), do: {:noreply, assign(socket, new_item_side: nil)}
  def handle_info({:cancel, %Item{id: _}}, socket), do: {:noreply, assign(socket, editing_item_id: nil)}


  @impl true
  def handle_info({:item_saved, _item}, socket) do
    collection = Collections.get_collection_with_items!(socket.assigns.collection.id)

    {:noreply,
     socket
     |> assign(:collection, collection)
     |> assign(:editing_item_id, nil)
     |> assign(:new_item_side, nil)
     |> put_flash(:info, "Item gespeichert.")}
  end

  defp page_title(:show), do: "Show Collection"
  defp page_title(:edit), do: "Edit Collection"
end
