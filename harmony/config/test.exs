import Config

config :harmony, HarmonyWeb.Endpoint,
  http: [port: 4243],
  server: false

config :logger, level: :warning
