defmodule MatchMakerWeb.DashboardLive do
  use MatchMakerWeb, :live_view

  alias MatchMaker.Collections

  @impl true
  def mount(_params, _session, socket) do
    collections = Collections.list_collections_with_stats()

    {:ok,
     socket
     |> assign(:collections, collections)
     |> assign(:show_modal, false)
     |> assign(:form_action, :new)
     |> assign(:collection, %Collections.Collection{})
    }
  end


  def handle_event("new_collection", _, socket) do

    {:noreply,
     socket
     |> assign(:show_modal, true)
     |> assign(:modal_action, :new)
     |> assign(:collection, %Collections.Collection{})
    }
  end

  @impl true
  def handle_event("edit_collection", %{"id" => id}, socket) do
    collection = Collections.get_collection!(id)
    changeset = Collections.change_collection(collection)

    {:noreply,
     socket
     |> assign(:show_modal, true)
     |> assign(:form_action, :edit)
     |> assign(:collection, collection)
     # |> assign(:collection_changeset, changeset)
    }
  end

  # @impl true
  # def handle_event("validate_collection", %{"collection" => params}, socket) do
  #   changeset =
  #     socket.assigns.collection_changeset
  #     |> Collections.change_collection(params)
  #     |> Map.put(:action, :validate)

  #   {:noreply, assign(socket, collection_changeset: changeset)}
  # end

  # @impl true
  # def handle_event("save_collection", %{"collection" => params}, socket) do
  #   case Collections.update_collection(socket.assigns.collection, params) do
  #     {:ok, updated} ->
  #       {:noreply,
  #        socket
  #        |> put_flash(:info, "Collection gespeichert.")
  #        |> assign(collection: updated)
  #        |> assign(editing_collection: false)
  #        |> assign(collection_changeset: Collections.change_collection(updated))}

  #     {:error, changeset} ->
  #       {:noreply, assign(socket, collection_changeset: changeset)}
  #   end
  # end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply,
     socket
     |> assign(:show_modal, false)
     |> push_event("close_modal", %{id: "collection-modal"})
     |> push_event("restore_scroll", %{})
    }
  end

  @impl true
  def handle_info(:collection_saved, socket) do
    collections = Collections.list_collections_with_stats()

    {:noreply,
     socket
     |> put_flash(:info, "Collection gespeichert.")
     |> assign(:collections, collections)
     |> assign(:form_action, :new)
     |> assign(:collection, %Collections.Collection{})
     |> assign(:show_modal, false)
    |> push_event("restore_scroll", %{})}
end

end
