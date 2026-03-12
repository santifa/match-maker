defmodule MatchMakerWeb.Router do
  use MatchMakerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MatchMakerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :assign_current_user
  end

  # Make the current user accessible for all templates
  defp assign_current_user(conn, _opts) do
    assign(conn, :current_user, get_session(conn, :current_user))
  end

  pipeline :api do
    plug :accepts, ["json"]
  end


  scope "/" , MatchMakerWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/collections/export/json", PageController, :export_json
  end

  scope "/dashboard", MatchMakerWeb do
    pipe_through :browser

    live "/", DashboardLive, :index
    live "/settings", SettingsLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", MatchMakerWeb do
  #   pipe_through :api
  # end
  scope "/auth", MatchMakerWeb do
    pipe_through :browser

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    post "/:provider/callback", AuthController, :callback
    delete "/logout", AuthController, :delete
  end



  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:match_maker, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MatchMakerWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
