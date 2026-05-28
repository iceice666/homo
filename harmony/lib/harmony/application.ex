defmodule Harmony.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Harmony.Registry},
      Harmony.TicketCache,
      {DynamicSupervisor, name: Harmony.ProjectSupervisor, strategy: :one_for_one},
      HarmonyWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Harmony.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
