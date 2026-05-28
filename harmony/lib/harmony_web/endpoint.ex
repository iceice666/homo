defmodule HarmonyWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :harmony

  socket "/socket", HarmonyWeb.UserSocket,
    websocket: true,
    longpoll: false

  plug Plug.RequestId
  plug Plug.Logger
  plug Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
end
