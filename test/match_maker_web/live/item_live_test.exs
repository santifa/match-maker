defmodule MatchMakerWeb.ItemLiveTest do
  use MatchMakerWeb.ConnCase

  import Phoenix.LiveViewTest
  import MatchMaker.AccountsFixtures
  import MatchMaker.CollectionsFixtures

  setup do
    Application.put_env(:match_maker, :allowed_domains, ["example.com"])
    :ok
  end

  test "dashboard opens the item editor for a collection", %{conn: conn} do
    admin = admin_fixture()
    collection = collection_fixture()
    item = item_fixture(collection)

    conn = init_test_session(conn, %{"current_user" => admin})
    {:ok, view, _html} = live(conn, ~p"/dashboard")

    view
    |> element("button", "Edit items")
    |> render_click()

    assert render(view) =~ item.name
  end

  test "dashboard item editor shows both collection sides", %{conn: conn} do
    admin = admin_fixture()
    collection = collection_fixture()
    left = item_fixture(collection, %{side: :left, name: "Person in editor"})
    right = item_fixture(collection, %{side: :right, name: "Task in editor"})

    conn = init_test_session(conn, %{"current_user" => admin})
    {:ok, view, _html} = live(conn, ~p"/dashboard")

    view
    |> element("button", "Edit items")
    |> render_click()

    html = render(view)
    assert html =~ left.name
    assert html =~ right.name
  end
end
