defmodule MatchMaker.Collections.Collection do
  use Ecto.Schema
  import Ecto.Changeset

  schema "collections" do
    field :name, :string
    field :description, :string
    field :webhook_url, :string
    field :webhook_template, :string, default: ""
    field :cron_expression, :string
    field :last_matched_at, :utc_datetime_usec

    has_many :items, MatchMaker.Collections.Item, on_delete: :delete_all

    has_many :left_items, MatchMaker.Collections.Item,
             foreign_key: :collection_id,
             where: [side: :left]

    has_many :right_items, MatchMaker.Collections.Item,
             foreign_key: :collection_id,
             where: [side: :right]

    has_many :matches, MatchMaker.Collections.Match

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(collection, attrs) do
    collection
    |> cast(attrs, [:name, :description, :webhook_url, :webhook_template, :cron_expression])
    # |> put_change(:webhook_template, Map.get(attrs, "webhook_template") || "") # If default is not working
    |> validate_required([:name, :webhook_url])
    |> validate_format(:webhook_url, ~r/^https?:\/\/[^\s]+$/, message: "not a valid URL")
    |> validate_change(:cron_expression, fn :cron_expression, val ->
      case :ecron.parse_spec(val, 1) do
        {:ok, _} -> []
        {:error, _, _} -> [cron_expression: "is not a valid cron expression"]
      end
    end)
  end
end
