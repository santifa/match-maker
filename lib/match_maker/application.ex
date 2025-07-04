defmodule MatchMaker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MatchMakerWeb.Telemetry,
      MatchMaker.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:match_maker, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:match_maker, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: MatchMaker.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: MatchMaker.Finch},
      # Start a worker by calling: MatchMaker.Worker.start_link(arg)
      # {MatchMaker.Worker, arg},
      # Start to serve requests, typically the last entry
      MatchMakerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MatchMaker.Supervisor]
    tree = Supervisor.start_link(children, opts)

    # Start cron jobs for matchings, a working database is needed for this step
    Task.start(fn -> MatchMaker.Cron.register_all_cron_jobs() end)
    # Return the supervision tree
    tree
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MatchMakerWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") != nil
  end
end
