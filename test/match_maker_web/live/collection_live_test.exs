defmodule MatchMakerWeb.CollectionLiveTest do
  use MatchMakerWeb.ConnCase

  import Phoenix.LiveViewTest
  import MatchMaker.AccountsFixtures
  import MatchMaker.CollectionsFixtures

  alias MatchMaker.Collections

  setup do
    Application.put_env(:match_maker, :allowed_domains, ["example.com"])
    :ok
  end

  defp dashboard_conn(conn, admin) do
    init_test_session(conn, %{"current_user" => admin})
  end

  test "dashboard lists collections", %{conn: conn} do
    admin = admin_fixture()
    collection = collection_fixture()

    {:ok, _view, html} =
      conn
      |> dashboard_conn(admin)
      |> live(~p"/dashboard")

    assert html =~ collection.name
    assert html =~ "Run matching"
  end

  test "collection editor exposes the matching algorithm selector", %{conn: conn} do
    admin = admin_fixture()
    collection = collection_fixture()

    {:ok, view, _html} =
      conn
      |> dashboard_conn(admin)
      |> live(~p"/dashboard")

    view
    |> element("button", "Edit collection")
    |> render_click()

    html = render(view)
    assert html =~ "Matching algorithm"
    assert html =~ "Randomized round-robin"
    assert html =~ "Greedy history-aware"
    assert html =~ ~s(value="#{collection.matching_algorithm}")
  end

  test "dashboard can run a collection match", %{conn: conn} do
    admin = admin_fixture()
    collection = collection_fixture(%{webhook_url: nil})
    _left = item_fixture(collection, %{side: :left})
    _right = item_fixture(collection, %{side: :right})

    {:ok, view, _html} =
      conn
      |> dashboard_conn(admin)
      |> live(~p"/dashboard")

    view
    |> element(~s(button[phx-value-id="#{collection.id}"]), "Run matching")
    |> render_click()

    assert render(view) =~ "Run match for #{collection.name}"
  end

  test "history modal shows recent assignments and can be reopened", %{conn: conn} do
    admin = admin_fixture()
    collection = collection_fixture(%{webhook_url: nil})
    left = item_fixture(collection, %{side: :left, name: "History person"})
    right = item_fixture(collection, %{side: :right, name: "History task"})

    assert {:ok, _match} = Collections.create_match(collection, [{right.id, left.id}])

    {:ok, view, _html} =
      conn
      |> dashboard_conn(admin)
      |> live(~p"/dashboard")

    show_history =
      element(view, ~s(button[phx-click="show_matches"][phx-value-id="#{collection.id}"]))

    render_click(show_history)
    html = render(view)
    assert html =~ "Match history: #{collection.name}"
    assert html =~ left.name
    assert html =~ right.name

    view
    |> element("#history-modal button[aria-label=\"close\"]")
    |> render_click()

    refute has_element?(view, "#history-modal")

    render_click(show_history)
    assert has_element?(view, "#history-modal")
    assert render(view) =~ left.name
  end

  test "history modal clearly shows when there are no matches", %{conn: conn} do
    admin = admin_fixture()
    collection = collection_fixture(%{webhook_url: nil})

    {:ok, view, _html} =
      conn
      |> dashboard_conn(admin)
      |> live(~p"/dashboard")

    view
    |> element(~s(button[phx-click="show_matches"][phx-value-id="#{collection.id}"]))
    |> render_click()

    assert render(view) =~ "No matches have been run for this collection yet."
  end

  test "history modal refreshes when switching collections", %{conn: conn} do
    admin = admin_fixture()
    first_collection = collection_fixture(%{webhook_url: nil})
    second_collection = collection_fixture(%{webhook_url: nil})
    first_left = item_fixture(first_collection, %{side: :left, name: "First person"})
    first_right = item_fixture(first_collection, %{side: :right, name: "First task"})
    second_left = item_fixture(second_collection, %{side: :left, name: "Second person"})
    second_right = item_fixture(second_collection, %{side: :right, name: "Second task"})

    assert {:ok, _} =
             Collections.create_match(first_collection, [{first_right.id, first_left.id}])

    assert {:ok, _} =
             Collections.create_match(second_collection, [{second_right.id, second_left.id}])

    {:ok, view, _html} =
      conn
      |> dashboard_conn(admin)
      |> live(~p"/dashboard")

    show_history = fn collection ->
      view
      |> element(~s(button[phx-click="show_matches"][phx-value-id="#{collection.id}"]))
      |> render_click()
    end

    show_history.(first_collection)
    assert render(view) =~ "Match history: #{first_collection.name}"
    assert render(view) =~ first_left.name

    show_history.(second_collection)
    html = render(view)
    assert html =~ "Match history: #{second_collection.name}"
    assert html =~ second_left.name
  end
end
