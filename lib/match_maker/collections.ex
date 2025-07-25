defmodule MatchMaker.Collections do
  @moduledoc """
  The Collections context.
  """

  import Ecto.Query, warn: false
  alias MatchMaker.Repo

  alias MatchMaker.Collections.Collection
  alias MatchMaker.Collections.Match
  alias MatchMaker.Collections.MatchAssignment

  @doc """
  Returns the list of collections.

  ## Examples

      iex> list_collections()
      [%Collection{}, ...]

  """
  def list_collections do
    Repo.all(Collection)
  end

  @doc """
  Gets a single collection.

  Raises `Ecto.NoResultsError` if the Collection does not exist.

  ## Examples

      iex> get_collection!(123)
      %Collection{}

      iex> get_collection!(456)
      ** (Ecto.NoResultsError)

  """
  def get_collection!(id), do: Repo.get!(Collection, id)

  def get_collection_with_items!(id) do
    Collection
    |> Repo.get!(id)
    |> Repo.preload([:left_items, :right_items])
  end

  @doc """
  Creates a collection.

  ## Examples

      iex> create_collection(%{field: value})
      {:ok, %Collection{}}

      iex> create_collection(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_collection(attrs \\ %{}) do
    %Collection{}
    |> Collection.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a collection.

  ## Examples

      iex> update_collection(collection, %{field: new_value})
      {:ok, %Collection{}}

      iex> update_collection(collection, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_collection(%Collection{} = collection, attrs) do
    collection
    |> Collection.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a collection.

  ## Examples

      iex> delete_collection(collection)
      {:ok, %Collection{}}

      iex> delete_collection(collection)
      {:error, %Ecto.Changeset{}}

  """
  def delete_collection(%Collection{} = collection) do
    Repo.delete(collection)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking collection changes.

  ## Examples

      iex> change_collection(collection)
      %Ecto.Changeset{data: %Collection{}}

  """
  def change_collection(%Collection{} = collection, attrs \\ %{}) do
    Collection.changeset(collection, attrs)
  end

  alias MatchMaker.Collections.Item

  @doc """
  Returns the list of items.

  ## Examples

      iex> list_items()
      [%Item{}, ...]

  """
  def list_items do
    Repo.all(Item)
  end

  @doc """
  Gets a single item.

  Raises `Ecto.NoResultsError` if the Item does not exist.

  ## Examples

      iex> get_item!(123)
      %Item{}

      iex> get_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_item!(id), do: Repo.get!(Item, id)

  @doc """
  Creates a item.

  ## Examples

      iex> create_item(%{field: value})
      {:ok, %Item{}}

      iex> create_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_item(attrs \\ %{}) do
    %Item{}
    |> Item.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a item.

  ## Examples

      iex> update_item(item, %{field: new_value})
      {:ok, %Item{}}

      iex> update_item(item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_item(%Item{} = item, attrs) do
    item
    |> Item.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a item.

  ## Examples

      iex> delete_item(item)
      {:ok, %Item{}}

      iex> delete_item(item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_item(%Item{} = item) do
    Repo.delete(item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking item changes.

  ## Examples

      iex> change_item(item)
      %Ecto.Changeset{data: %Item{}}

  """
  def change_item(%Item{} = item, attrs \\ %{}) do
    Item.changeset(item, attrs)
  end

  def create_match(collection, assignments) do
    %Match{}
    |> Match.changeset(%{collection_id: collection.id})
    |> Repo.insert()
    |> case do
      {:ok, match} ->
        match_assignments =
          Enum.map(assignments, fn {right_id, left_id} ->
            %{
              match_id: match.id,
              right_item_id: right_id,
              left_item_id: left_id,
              inserted_at: DateTime.truncate(DateTime.utc_now(), :second),
              updated_at: DateTime.truncate(DateTime.utc_now(), :second)
            }
          end)

        Repo.insert_all(MatchAssignment, match_assignments)
        {:ok, match}

      error ->
        error
    end
  end

  def validate_item_pair(%Match{} = match, %Item{} = left, %Item{} = right) do
    cond do
      left.collection_id != right.collection_id ->
        {:error, :mismatched_collections}

      left.collection_id != match.collection_id ->
        {:error, :not_part_of_match_collection}

      true ->
        :ok
    end
  end

  def get_last_match_with_assignments(collection_id) do
    Match
    |> where([m], m.collection_id == ^collection_id)
    |> order_by([m], desc: m.inserted_at)
    |> preload(match_assignments: [:left_item, :right_item])
    |> limit(1)
    |> Repo.one()
  end

  def list_matches_with_assignments(collection_id) do
    Match
    |> where([m], m.collection_id == ^collection_id)
    |> order_by(desc: :inserted_at)
    |> preload(match_assignments: [:left_item, :right_item])
    |> Repo.all()
  end

  def list_collections_with_stats() do
    collections =
      Repo.all(Collection)
      |> Repo.preload([:left_items, :right_items])

    Enum.map(
      collections,
      fn c ->
        case get_last_match_with_assignments(c.id) do
          nil ->
            c
            |> Map.put(:last_match, nil)
            |> Map.put(:last_match_run, "Not run")

          e ->
            c
            |> Map.put(:last_match, e)
            |> Map.put(:last_match_run, e.inserted_at |> Calendar.strftime("%d.%m.%Y %H:%M"))
        end
      end
    )
  end
end
