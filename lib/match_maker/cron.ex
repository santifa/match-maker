defmodule MatchMaker.Cron do
  alias MatchMaker.Collections
  alias MatchMaker.MatchRunner
  alias MatchMaker.Collections.Collection

  def register_cron_for_collection(%{id: _id, cron_expression: nil}), do: :noop

  def register_cron_for_collection(%Collection{id: id, cron_expression: expr} = _collection) do
    collection = Collections.get_collection_with_items!(id)
    job_name = "collection_#{id}_cron"
    mfa = {MatchMaker.Cron, :run_job, [collection]}
    options = %{max_runtime_ms: 1000}
    {:ok, ^job_name} = :ecron.create(job_name, expr, mfa, options)
  end

  def remove_cron_for_collection(%Collection{id: id} = _collection) do
    job_name = "collection_#{id}_cron"
    :ecron.delete(job_name)
  end

  def refresh_cron_for_collection(collection) do
    remove_cron_for_collection(collection)
    register_cron_for_collection(collection)
  end

  def get_info_for_cron(%Collection{id: id} = _collection) do
    job_name = "collection_#{id}_cron"
    :ecron.statistic(job_name)
  end

  def register_all_cron_jobs do
    for collection <- MatchMaker.Collections.list_collections() do
      register_cron_for_collection(collection)
    end
  end

  def run_job(collection) do
    MatchRunner.run(collection)
  end
end
