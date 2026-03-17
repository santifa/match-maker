defmodule MatchMaker.Collections.Collection do
  use Ecto.Schema
  import Ecto.Changeset

  schema "collections" do
    field :name, :string
    field :description, :string
    field :webhook_url, :string
    field :webhook_template, :string, default: ""
    field :cron_expression, :string
    field :cron_interval, :integer, default: 0
    field :cron_counter, :integer, default: 0
    field :last_matched_at, :utc_datetime_usec
    field :enabled, :boolean, default: true

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
    |> cast(attrs, [
      :name,
      :description,
      :webhook_url,
      :webhook_template,
      :cron_expression,
      :enabled,
      :cron_interval,
      :cron_counter
    ])
    |> validate_required([:name, :enabled])
    |> validate_length(:name, max: 255)
    |> validate_length(:webhook_template, max: 4_000)
    |> validate_webhook_url()
    |> validate_cron_expression()
    |> validate_number(:cron_interval, greater_than_or_equal_to: 0, less_than_or_equal_to: 1_000)
    |> validate_number(:cron_counter, greater_than_or_equal_to: 0)
    |> unique_constraint(:name)
  end

  defp validate_webhook_url(changeset) do
    validate_change(changeset, :webhook_url, fn :webhook_url, url ->
      cond do
        is_nil(url) or url == "" -> []
        String.length(url) > 2_048 -> [webhook_url: "is too long"]
        String.match?(url, ~r/^https?:\/\/[^\s]+$/) -> []
        true -> [webhook_url: "not a valid URL"]
      end
    end)
  end

  defp validate_cron_expression(changeset) do
    validate_change(changeset, :cron_expression, fn :cron_expression, expression ->
      cond do
        is_nil(expression) or expression == "" -> []
        match?({:ok, _}, :ecron.parse_spec(expression, 1)) -> []
        true -> [cron_expression: "is not a valid cron expression"]
      end
    end)
  end

  defimpl Jason.Encoder, for: [__MODULE__] do
    def encode(struct, opts) do
      Enum.reduce(Map.from_struct(struct), %{}, fn
        ({_k, %Ecto.Association.NotLoaded{}}, acc) -> acc
        ({k, v}, acc) -> Map.reject(acc, fn {k, _v} -> k === :__meta__ end) |> Map.put(k, v)
      end)
      |> Jason.Encode.map(opts)
    end
  end
end
