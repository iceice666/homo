defmodule HarmonyWeb.UserSocket do
  use Phoenix.Socket

  channel "projects:lobby", HarmonyWeb.LobbyChannel
  channel "project:*", HarmonyWeb.ProjectChannel

  @impl true
  def connect(%{"token" => _token}, socket, _connect_info) do
    # TODO: validate token against ~/.score/config.yaml api_token
    {:ok, socket}
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(_socket), do: nil
end
