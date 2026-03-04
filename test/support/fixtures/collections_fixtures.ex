defmodule MatchMaker.CollectionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MatchMaker.Collections` context.
  """

  alias MatchMaker.Collections

  def unique_collection_name, do: "Collection #{System.unique_integer()}"
  def unique_item_name, do: "Item #{System.unique_integer()}"

  @doc """
  Generate a collection.
  """
  def collection_fixture(attrs \\ %{}) do
    {:ok, collection} =
      attrs
      |> Enum.into(%{
        name: unique_collection_name(),
        description: "some description",
        webhook_template: "some webhook_template",
        webhook_url: "https://example.com/webhook",
        cron_expression: "* * * * *",
        enabled: true
      })
      |> Collections.create_collection()

    collection
  end

  @doc """
  Generate a item.
  """
  def item_fixture(collection, attrs \\ %{}) do
    {:ok, item} =
      attrs
      |> Enum.into(%{
        name: unique_item_name(),
        description: "A test item",
        side: :left, # Enum default
        enabled: true,
        collection_id: collection.id # Link to parent
      })
      |> Collections.create_item()

    item
  end
end
