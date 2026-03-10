defmodule MatchMakerWeb.SettingsGeneralComponent do
	use MatchMakerWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
    <.h2>General Settings</.h2>
    <.p>See the sidebar for more settings</.p>
    </div>
    """
  end
end
