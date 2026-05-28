import Config

if config_env() == :prod do
  port = System.get_env("PORT", "4242") |> String.to_integer()

  config :harmony, HarmonyWeb.Endpoint,
    http: [port: port],
    secret_key_base: System.fetch_env!("SECRET_KEY_BASE")
end
