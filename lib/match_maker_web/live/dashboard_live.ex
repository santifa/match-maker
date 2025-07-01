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
     |> assign(:show_item_modal, false)
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

    {:noreply,
     socket
     |> assign(:show_modal, true)
     |> assign(:form_action, :edit)
     |> assign(:collection, collection)
    }
  end

  @impl true
  def handle_event("delete_collection", %{"id" => id}, socket) do
    collection = Collections.get_collection!(id)
    Collections.delete_collection(collection)
    collections = Collections.list_collections_with_stats()

    {:noreply,
     socket
     |> put_flash(:info, "Collection gelöscht.")
     |> assign(:collections, collections)}
  end

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
  def handle_event("edit_items", %{"id" => id}, socket) do
    collection = Collections.get_collection_with_items!(id)

    {:noreply,
     socket
     |> assign(:show_item_modal, true)
     |> assign(:collection, collection)
    }
  end

  @impl true
  def handle_event("close_item_modal", _, socket) do
    {:noreply,
     socket
     |> assign(:show_item_modal, false)
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

  @impl true
  def handle_info({:reload_collection, id}, socket) do
    collections = Collections.list_collections_with_stats()
    collection = Collections.get_collection_with_items!(id)

    {:noreply,
     socket
     |> assign(:collections, collections)
     |> assign(:collection, collection)
     |> assign(:show_item_modal, true)}
  end
end
