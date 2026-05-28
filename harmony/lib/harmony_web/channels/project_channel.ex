defmodule HarmonyWeb.ProjectChannel do
  use Phoenix.Channel

  @impl true
  def join("project:" <> project_id, _params, socket) do
    socket = assign(socket, :project_id, project_id)
    {:ok, socket}
  end

  # Server → Client pushes (CONTRACT.md):
  #   ticket:changed    run:started    run:progress    run:finished    run:needs_input
  # Triggered by TicketCache updates and Dispatcher events; not client-initiated.

  @impl true
  def handle_in(_event, _payload, socket) do
    {:noreply, socket}
  end
end
