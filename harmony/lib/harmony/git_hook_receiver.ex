defmodule Harmony.GitHookReceiver do
  use GenServer

  # Listens on a Unix socket for post-commit / post-merge signals from installed git hooks.
  # On signal: reads changed ticket paths via git diff-tree, re-reads files via git show,
  # updates TicketCache, broadcasts events.
  # Started per-project by Harmony.ProjectSupervisor.

  def start_link(opts) do
    project_id = Keyword.fetch!(opts, :project_id)
    GenServer.start_link(__MODULE__, opts, name: via(project_id))
  end

  defp via(project_id), do: {:via, Registry, {Harmony.Registry, {__MODULE__, project_id}}}

  # TODO: open Unix socket at project socket path
  # TODO: handle post-commit / post-merge → diff → update cache → broadcast

  @impl true
  def init(opts) do
    {:ok, %{project_id: Keyword.fetch!(opts, :project_id)}}
  end
end
