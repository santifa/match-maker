defmodule MatchMaker.CollectionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MatchMaker.Collections` context.
  """

  @doc """
  Generate a collection.
  """
  def collection_fixture(attrs \\ %{}) do
    {:ok, collection} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name",
        webhook_template: "some webhook_template",
        webhook_url: "some webhook_url"
      })
      |> MatchMaker.Collections.create_collection()

    collection
  end

  @doc """
  Generate a item.
  """
  def item_fixture(attrs \\ %{}) do
    {:ok, item} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name"
      })
      |> MatchMaker.Collections.create_item()

    item
  end
end
