defmodule MatchMakerWeb.MatchViewerComponent do
  use MatchMakerWeb, :live_component

  def update(assigns, socket) do
    {:ok,
     socket
    |> assign(assigns)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.modal
        id="collection-modal"
        show={@show_matches_modal}
        on_cancel={JS.push("close_modal")}
        title={@collection.name}
      >
        Modal on
      </.modal>
    </div>
    """
  end
end
