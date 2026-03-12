defmodule MatchMakerWeb.PageController do
  @moduledoc """
  Static page controller needed for the login and registration pages
  which are static sites while the main application uses live view.
  """

  use MatchMakerWeb, :controller
  alias MatchMaker.Collections
  alias MatchMaker.Accounts

  def index(conn, _params) do
    case get_session(conn, :current_user) do
      nil -> render(conn, :index, current_user: nil)
      _ -> redirect(conn, to: ~p"/dashboard")
    end
  end

  def export_json(conn, _params) do
    user = get_session(conn, :current_user)
    case Accounts.is_admin?(user) do
      false -> render(conn, :index, current_user: nil)
      true ->
        data = Collections.list_collections()
        json = Jason.encode!(data)

        conn
        |> put_resp_content_type("application/json")
        |> put_resp_header("content-disposition", ~s[attachment;filename="collections.json"])
        |> send_resp(200, json)
    end
  end
end
