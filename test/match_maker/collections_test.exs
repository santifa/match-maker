defmodule MatchMaker.CollectionsTest do
  use MatchMaker.DataCase

  alias MatchMaker.Collections

  describe "collections" do
    alias MatchMaker.Collections.Collection

    import MatchMaker.CollectionsFixtures

    @invalid_attrs %{name: nil, description: nil, webhook_url: nil, webhook_template: nil}

    test "list_collections/0 returns all collections" do
      collection = collection_fixture()
      assert Collections.list_collections() == [collection]
    end

    test "get_collection!/1 returns the collection with given id" do
      collection = collection_fixture()
      assert Collections.get_collection!(collection.id) == collection
    end

    test "create_collection/1 with valid data creates a collection" do
      valid_attrs = %{name: "some name", description: "some description", webhook_url: "some webhook_url", webhook_template: "some webhook_template"}

      assert {:ok, %Collection{} = collection} = Collections.create_collection(valid_attrs)
      assert collection.name == "some name"
      assert collection.description == "some description"
      assert collection.webhook_url == "some webhook_url"
      assert collection.webhook_template == "some webhook_template"
    end

    test "create_collection/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Collections.create_collection(@invalid_attrs)
    end

    test "update_collection/2 with valid data updates the collection" do
      collection = collection_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description", webhook_url: "some updated webhook_url", webhook_template: "some updated webhook_template"}

      assert {:ok, %Collection{} = collection} = Collections.update_collection(collection, update_attrs)
      assert collection.name == "some updated name"
      assert collection.description == "some updated description"
      assert collection.webhook_url == "some updated webhook_url"
      assert collection.webhook_template == "some updated webhook_template"
    end

    test "update_collection/2 with invalid data returns error changeset" do
      collection = collection_fixture()
      assert {:error, %Ecto.Changeset{}} = Collections.update_collection(collection, @invalid_attrs)
      assert collection == Collections.get_collection!(collection.id)
    end

    test "delete_collection/1 deletes the collection" do
      collection = collection_fixture()
      assert {:ok, %Collection{}} = Collections.delete_collection(collection)
      assert_raise Ecto.NoResultsError, fn -> Collections.get_collection!(collection.id) end
    end

    test "change_collection/1 returns a collection changeset" do
      collection = collection_fixture()
      assert %Ecto.Changeset{} = Collections.change_collection(collection)
    end
  end

  describe "items" do
    alias MatchMaker.Collections.Item

    import MatchMaker.CollectionsFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_items/0 returns all items" do
      item = item_fixture()
      assert Collections.list_items() == [item]
    end

    test "get_item!/1 returns the item with given id" do
      item = item_fixture()
      assert Collections.get_item!(item.id) == item
    end

    test "create_item/1 with valid data creates a item" do
      valid_attrs = %{name: "some name", description: "some description"}

      assert {:ok, %Item{} = item} = Collections.create_item(valid_attrs)
      assert item.name == "some name"
      assert item.description == "some description"
    end

    test "create_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Collections.create_item(@invalid_attrs)
    end

    test "update_item/2 with valid data updates the item" do
      item = item_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %Item{} = item} = Collections.update_item(item, update_attrs)
      assert item.name == "some updated name"
      assert item.description == "some updated description"
    end

    test "update_item/2 with invalid data returns error changeset" do
      item = item_fixture()
      assert {:error, %Ecto.Changeset{}} = Collections.update_item(item, @invalid_attrs)
      assert item == Collections.get_item!(item.id)
    end

    test "delete_item/1 deletes the item" do
      item = item_fixture()
      assert {:ok, %Item{}} = Collections.delete_item(item)
      assert_raise Ecto.NoResultsError, fn -> Collections.get_item!(item.id) end
    end

    test "change_item/1 returns a item changeset" do
      item = item_fixture()
      assert %Ecto.Changeset{} = Collections.change_item(item)
    end
  end
end
