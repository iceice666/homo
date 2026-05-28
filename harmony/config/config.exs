import Config

config :harmony, HarmonyWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  http: [port: 4242],
  secret_key_base: String.duplicate("a", 64),
  server: true

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
