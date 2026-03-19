defmodule MatchMakerWeb.SettingsGeneralComponent do
  use MatchMakerWeb, :live_component

  alias MatchMaker.Collections

  def update(_params, socket) do
    {:ok,
     socket
     |> assign(:import_file, [])
     |> allow_upload(:import_file,
                     accept: ~w(.json),
                     max_entries: 1,
                     max_file_size: 5_000_000)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-2 text-black min-w-full">
      <.h2>General Settings</.h2>

      <.tabs id="import-export" size="large" rounded="medium" gap="large">
        <:tab>Export</:tab>
        <:tab>Import</:tab>

        <:panel>
          <.button>
            <.link title="Export" href={~p"/collections/export/json"}>Collections</.link>
          </.button>
        </:panel>

        <:panel>
          <.form_wrapper id="upload-form" for={@uploads}
            phx-change="validate" phx-submit="import-collections" phx-target={@myself}>
            <.file_field name="file-upload" size="extra_small" class="text-sm"
              uploads={@uploads.import_file}/>
            <.button class="mt-2" type="submit">Upload Collections</.button>
          </.form_wrapper>
      </:panel>
      </.tabs>
    </div>
    """
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("import-collections", _params, socket) do
    result = consume_uploaded_entries(socket, :import_file, fn %{path: path},
                                                               _entry ->
      case Collections.import_from_json(path) do
        {:ok, _} = ok -> {:ok, ok}
        {:error, _} = err -> {:postpone, err}
      end
    end) |> List.first

    msg = case result do
      {:ok, _} -> {:flash, :info, "Successfully uploaded file"}
      {:error, _} -> {:flash, :error, "Failed to upload file"}
    end

    send(self(), msg)
    {:noreply, socket}
  end

end
