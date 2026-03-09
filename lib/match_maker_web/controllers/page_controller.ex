defmodule MatchMakerWeb.PageController do
  @moduledoc """
  Static page controller needed for the login and registration pages
  which are static sites while the main application uses live view.
  """

  use MatchMakerWeb, :controller

  def index(conn, _params) do
    case get_session(conn, :current_user) do
      nil -> render(conn, "index.html", current_user: nil)
      _ -> redirect(conn, to: ~p"/dashboard")
    end
  end
end
