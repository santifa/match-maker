defmodule MatchMaker.Collections.Item do
  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field :name, :string
    field :description, :string
    field :side, Ecto.Enum, values: [:left, :right]
    field :enabled, :boolean

    belongs_to :collection, MatchMaker.Collections.Collection

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:name, :description, :side, :collection_id, :enabled])
    |> validate_required([:name, :side, :collection_id, :enabled])
  end
end
