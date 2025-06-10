defmodule MatchMaker.Collections.Match do
  use Ecto.Schema
  import Ecto.Changeset

  schema "matches" do
    belongs_to :collection, MatchMaker.Collections.Collection
    has_many :match_assignments, MatchMaker.Collections.MatchAssignment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(match, attrs) do
      match
      |> cast(attrs, [:collection_id])
      |> validate_required([:collection_id])
      |> assoc_constraint(:collection)
  end
end
