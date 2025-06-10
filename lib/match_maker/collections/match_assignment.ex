defmodule MatchMaker.Collections.MatchAssignment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "match_assignments" do
    belongs_to :match, MatchMaker.Collections.Match
    belongs_to :right_item, MatchMaker.Collections.Item
    belongs_to :left_item, MatchMaker.Collections.Item

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(match_assignment, attrs) do
    match_assignment
    |> cast(attrs, [:match_id, :right_item_id, :left_item_id])
    |> validate_required([:match_id, :right_item_id, :left_item_id])
    |> assoc_constraint(:match)
    |> assoc_constraint(:right_item)
    |> assoc_constraint(:left_item)
  end
end
