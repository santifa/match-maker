defmodule MatchMaker.MatchRunner do


  def run(collection) do
    IO.inspect(collection, label: "RUN COLLECTION")
    # ... hier deine Logik, z. B. HTTP-Request mit webhook_url/template
    :ok
  end
end
