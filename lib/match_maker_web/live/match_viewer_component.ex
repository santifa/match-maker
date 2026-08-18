defmodule MatchMakerWeb.MatchViewerComponent do
  use MatchMakerWeb, :live_component

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.modal
        id="history-modal"
        show={@show_matches_modal}
        on_cancel={JS.push("close_matches_modal")}
        title={"Match history: #{@collection.name}"}
        size="large"
      >
        <%= if @matches == [] do %>
          <p class="text-sm text-zinc-600">No matches have been run for this collection yet.</p>
        <% else %>
          <div class="space-y-6">
            <%= for {match, index} <- Enum.with_index(@matches, 1) do %>
              <section class="rounded-lg border border-zinc-200 p-4">
                <div class="mb-3 flex items-center justify-between gap-4">
                  <h2 class="font-semibold">Match ##{index}</h2>
                  <time
                    class="text-sm text-zinc-500"
                    datetime={DateTime.to_iso8601(match.inserted_at)}
                  >
                    {format_match_time(match.inserted_at)}
                  </time>
                </div>

                <%= if match.match_assignments == [] do %>
                  <p class="text-sm text-zinc-600">This match contains no assignments.</p>
                <% else %>
                  <div class="grid grid-cols-[minmax(0,1fr)_auto_minmax(0,1fr)] gap-x-4 gap-y-2 text-sm">
                    <%= for assignment <- match.match_assignments do %>
                      <span class="truncate">{assignment.left_item.name}</span>
                      <span class="text-zinc-500">→</span>
                      <span class="truncate">{assignment.right_item.name}</span>
                    <% end %>
                  </div>
                <% end %>
              </section>
            <% end %>
          </div>
        <% end %>
      </.modal>
    </div>
    """
  end

  defp format_match_time(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")
  end
end
