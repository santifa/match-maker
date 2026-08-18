defmodule MatchMakerWeb.SettingsLiveTest do
  use MatchMakerWeb.ConnCase

  import Phoenix.LiveViewTest
  import MatchMaker.AccountsFixtures
  alias MatchMaker.Accounts

  setup do
    Application.put_env(:match_maker, :allowed_domains, ["example.com"])
    :ok
  end

  test "renders settings and lists users", %{conn: conn} do
    admin = admin_fixture()
    user = user_fixture()

    conn = init_test_session(conn, %{"current_user" => admin})

    {:ok, view, html} = live(conn, ~p"/dashboard/settings")

    assert html =~ "General Settings"
    assert html =~ "Export Collections"
    assert html =~ user.email
    assert html =~ admin.email

    # Render the upload form to ensure file input is present
    assert render(view) =~ ~s/phx-submit="import"/
  end

  test "changes role for a user", %{conn: conn} do
    admin = admin_fixture()
    user = user_fixture()

    conn = init_test_session(conn, %{"current_user" => admin})
    {:ok, view, _html} = live(conn, ~p"/dashboard/settings")

    view
    |> element("select[phx-value-user_id=\"#{user.id}\"]")
    |> render_click(%{"user_id" => "#{user.id}", "value" => "admin"})

    assert Accounts.get_user!(user.id).role == "admin"
    assert render(view) =~ "User updated successfully"
  end

  test "returns changeset on invalid role change", %{conn: conn} do
    admin = admin_fixture()
    user = user_fixture()

    conn = init_test_session(conn, %{"current_user" => admin})
    {:ok, view, _html} = live(conn, ~p"/dashboard/settings")

    view
    |> element("select[phx-value-user_id=\"#{user.id}\"]")
    |> render_click(%{"user_id" => "#{user.id}", "value" => "invalid"})

    assert Accounts.get_user!(user.id).role == "user"
    refute render(view) =~ "User updated successfully"
  end

  test "uploads collections successfully", %{conn: conn} do
    admin = admin_fixture()
    conn = init_test_session(conn, %{"current_user" => admin})

    {:ok, view, _html} = live(conn, ~p"/dashboard/settings")

    json =
      [
        %{"name" => "Imported #{System.unique_integer([:positive])}", "enabled" => true}
      ]
      |> Jason.encode!()

    upload =
      file_input(view, "#upload-form", :file, [
        %{
          name: "collections.json",
          content: json
        }
      ])

    render_upload(upload, "collections.json")
    render_submit(view, "import", %{})

    assert render(view) =~ "Successfully uploaded file"
  end

  test "shows error when upload is invalid", %{conn: conn} do
    admin = admin_fixture()
    conn = init_test_session(conn, %{"current_user" => admin})

    {:ok, view, _html} = live(conn, ~p"/dashboard/settings")

    json = Jason.encode!([%{"name" => nil}])

    upload =
      file_input(view, "#upload-form", :file, [
        %{
          name: "collections.json",
          content: json
        }
      ])

    render_upload(upload, "collections.json")
    render_submit(view, "import", %{})

    assert render(view) =~ "Failed to upload file"
  end
end
