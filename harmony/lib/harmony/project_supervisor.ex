defmodule Harmony.ProjectSupervisor do
  # DynamicSupervisor facade — wraps the top-level DynamicSupervisor named
  # Harmony.ProjectSupervisor and starts a per-project subtree.

  def start_project(project_id) do
    children = [
      {Harmony.GitHookReceiver, project_id: project_id},
      {Harmony.Dispatcher, project_id: project_id}
    ]

    spec = %{
      id: {__MODULE__, project_id},
      start:
        {Supervisor, :start_link,
         [children, [strategy: :one_for_one, name: via(project_id)]]},
      type: :supervisor,
      restart: :transient
    }

    DynamicSupervisor.start_child(Harmony.ProjectSupervisor, spec)
  end

  def stop_project(project_id) do
    case Registry.lookup(Harmony.Registry, {__MODULE__, project_id}) do
      [{pid, _}] -> DynamicSupervisor.terminate_child(Harmony.ProjectSupervisor, pid)
      [] -> :ok
    end
  end

  defp via(project_id), do: {:via, Registry, {Harmony.Registry, {__MODULE__, project_id}}}
end
