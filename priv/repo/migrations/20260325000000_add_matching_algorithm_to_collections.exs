defmodule MatchMaker.Repo.Migrations.AddMatchingAlgorithmToCollections do
  use Ecto.Migration

  def change do
    alter table(:collections) do
      add :matching_algorithm, :string,
        null: false,
        default: "randomized_round_robin"
    end
  end
end
