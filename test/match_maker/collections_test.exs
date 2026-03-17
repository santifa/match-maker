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
      valid_attrs = %{name: "some name", description: "some description", webhook_url: "https://ex.com", webhook_template: "some webhook_template", enabled: true}

      assert {:ok, %Collection{} = collection} = Collections.create_collection(valid_attrs)
      assert collection.name == "some name"
      assert collection.description == "some description"
      assert collection.webhook_url == "https://ex.com"
      assert collection.webhook_template == "some webhook_template"
    end

    test "create_collection/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Collections.create_collection(@invalid_attrs)
    end

    test "update_collection/2 with valid data updates the collection" do
      collection = collection_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description", webhook_url: "https://ex.com", webhook_template: "some updated webhook_template"}

      assert {:ok, %Collection{} = collection} = Collections.update_collection(collection, update_attrs)
      assert collection.name == "some updated name"
      assert collection.description == "some updated description"
      assert collection.webhook_url == "https://ex.com"
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
      item = item_fixture(collection_fixture())
      assert Collections.list_items() == [item]
    end

    test "get_item!/1 returns the item with given id" do
      item = item_fixture(collection_fixture())
      assert Collections.get_item!(item.id) == item
    end

    test "create_item/1 with valid data creates a item" do
      collection = collection_fixture()
      valid_attrs = %{name: "some name", description: "some description", side: :left, enabled: true, collection_id: collection.id}

      assert {:ok, %Item{} = item} = Collections.create_item(valid_attrs)
      assert item.name == "some name"
      assert item.description == "some description"
    end

    test "create_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Collections.create_item(@invalid_attrs)
    end

    test "update_item/2 with valid data updates the item" do
      item = item_fixture(collection_fixture())
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %Item{} = item} = Collections.update_item(item, update_attrs)
      assert item.name == "some updated name"
      assert item.description == "some updated description"
    end

    test "update_item/2 with invalid data returns error changeset" do
      item = item_fixture(collection_fixture())
      assert {:error, %Ecto.Changeset{}} = Collections.update_item(item, @invalid_attrs)
      assert item == Collections.get_item!(item.id)
    end

    test "delete_item/1 deletes the item" do
      item = item_fixture(collection_fixture())
      assert {:ok, %Item{}} = Collections.delete_item(item)
      assert_raise Ecto.NoResultsError, fn -> Collections.get_item!(item.id) end
    end

    test "change_item/1 returns a item changeset" do
      item = item_fixture(collection_fixture())
      assert %Ecto.Changeset{} = Collections.change_item(item)
    end
  end

  describe "collection changesets" do
    alias MatchMaker.Collections.Collection
    import MatchMaker.CollectionsFixtures

    test "webhook_url has valid format" do
      collection = collection_changeset_fixture()
      changeset = Collection.changeset(collection, %{webhook_url: "https://ok.example.com/hook"})
      assert changeset.valid?
    end

    test "webhook_url has invalid format" do
      collection = collection_changeset_fixture()
      changeset = Collection.changeset(collection, %{webhook_url: "not valid"})
      assert changeset.errors == [webhook_url: {"not a valid URL", []}]
    end

    test "webhook_url has invalid http format" do
      collection = collection_changeset_fixture()
      changeset = Collections.change_collection(collection, %{webhook_url: "https://a b"})
      assert changeset.errors == [webhook_url: {"not a valid URL", []}]
    end

    test "webhook_url is too long" do
      collection = collection_changeset_fixture()
      url = String.pad_trailing("https://a.com/", 4_048, "b")
      changeset = Collections.change_collection(collection, %{webhook_url: url})
      assert changeset.errors == [webhook_url: {"is too long", []}]
    end

    test "cron_expression is invalid" do
      collection = collection_changeset_fixture()
      changeset = Collections.change_collection(collection, %{cron_expression: "* 9"})
      assert changeset.errors == [cron_expression: {"is not a valid cron expression", []}]
    end

    test "cron_expression is valid" do
      collection = collection_changeset_fixture()
      changeset = Collections.change_collection(collection, %{cron_expression: "0 9 * * *"})
      assert changeset.valid?
    end

    test "cron_expression is nil" do
      collection = collection_changeset_fixture()
      changeset = Collections.change_collection(collection, %{cron_expression: nil})
      assert changeset.valid?
    end

    test "cron_expression is empty" do
      collection = collection_changeset_fixture()
      changeset = Collections.change_collection(collection, %{cron_expression: ""})
      assert changeset.valid?
    end

    test "cron_interval above 1_000 is invalid" do
      collection = collection_changeset_fixture()
      changeset = Collections.change_collection(collection, %{cron_interval: 2_000})
      assert changeset.errors == [cron_interval: {"must be less than or equal to %{number}", [{:validation, :number}, {:kind, :less_than_or_equal_to}, {:number, 1000}]}]
    end

    test "cron_interval below 0 is invalid" do
      collection = collection_changeset_fixture()
      changeset = Collections.change_collection(collection, %{cron_interval: -1})
      assert changeset.errors == [cron_interval: {"must be greater than or equal to %{number}", [{:validation, :number}, {:kind, :greater_than_or_equal_to}, {:number, 0}]}]
    end

    test "cron_interval in bounds passes" do
      collection = collection_changeset_fixture()
      changeset = Collections.change_collection(collection, %{cron_interval: 3})
      assert changeset.valid?
    end

    test "cron_counter below 0 is invalid" do
      collection = collection_changeset_fixture()
      changeset = Collections.change_collection(collection, %{cron_counter: -1})
      assert changeset.errors == [cron_counter: {"must be greater than or equal to %{number}", [{:validation, :number}, {:kind, :greater_than_or_equal_to}, {:number, 0}]}]
    end

    test "collection names are unique" do
      collection = collection_fixture()
      attrs = Map.from_struct(collection)
      assert {:error, changeset} = Collections.create_collection(attrs)
      assert changeset.errors == [name: {"has already been taken",
           [constraint: :unique, constraint_name: "collections_name_index"]}
        ]
    end
  end

  describe "consume_cron_counter/1" do
    import MatchMaker.CollectionsFixtures

    test "runs immediately when interval is 0" do
      collection = collection_fixture(cron_interval: 0, cron_counter: 0)
      assert {:run, new_collection} = Collections.consume_cron_counter(collection)
      assert 0 == new_collection.cron_counter
    end

    test "increments counter and skips until threshold" do
      collection = collection_fixture(cron_interval: 3, cron_counter: 0)
      assert {:skip, new_collection} = Collections.consume_cron_counter(collection)
      assert 1 == new_collection.cron_counter
    end

    test "resets counter and runs at threshold" do
      collection = collection_fixture(cron_interval: 3, cron_counter: 2)
      assert {:run, new_collection} = Collections.consume_cron_counter(collection)
      assert 0 == new_collection.cron_counter
    end
  end

  describe "import_from_json/1" do
    test "import valid collection list" do
      path = Path.join(System.tmp_dir!(), "collections.json")
      File.write!(path, ~s([{"name":"Imported","enabled":true,"webhook_url":null}]))
      assert {:ok, 1} = Collections.import_from_json(path)
    end

    test "return invalid_format on non-list JSON" do
      path = Path.join(System.tmp_dir!(), "collections_invalid.json")
      File.write!(path, ~s({"name":"bad"}))
      assert {:error, :invalid_format} = Collections.import_from_json(path)
    end

    test "rolls back on invalid collection attributes" do
      path = Path.join(System.tmp_dir!(), "collections_bad_item.json")
      File.write!(path, ~s([{"name":null}]))
      assert {:error, {:invalid, %Ecto.Changeset{}}} = Collections.import_from_json(path)
    end
  end
end
