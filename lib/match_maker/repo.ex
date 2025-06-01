defmodule MatchMaker.Repo do
  use Ecto.Repo,
    otp_app: :match_maker,
    adapter: Ecto.Adapters.SQLite3
end
