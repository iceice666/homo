defmodule Harmony.Dispatcher do
  use GenServer

  # Manages run state and Voice subprocess pool for a single project.
  # Started per-project by Harmony.ProjectSupervisor.

  def start_link(opts) do
    project_id = Keyword.fetch!(opts, :project_id)
    GenServer.start_link(__MODULE__, opts, name: via(project_id))
  end

  defp via(project_id), do: {:via, Registry, {Harmony.Registry, {__MODULE__, project_id}}}

  # TODO: dispatch(ticket_id, cli) — spawn Voice port, track run state
  # TODO: cancel(run_id) — send SIGTERM, await exit 5
  # TODO: handle_info({port, {:exit_status, code}}) — map exit code → ticket transition

  @impl true
  def init(opts) do
    {:ok, %{project_id: Keyword.fetch!(opts, :project_id), runs: %{}}}
  end
end
