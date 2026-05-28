defmodule HarmonyWeb.LobbyChannel do
  use Phoenix.Channel

  @impl true
  def join("projects:lobby", _params, socket) do
    {:ok, socket}
  end

  # Client → Server events (CONTRACT.md)

  @impl true
  def handle_in("ticket:list", %{"project_id" => _project_id}, socket) do
    # TODO: read tickets from TicketCache for project; push ticket:changed for each
    {:noreply, socket}
  end

  def handle_in("ticket:create", _payload, socket) do
    # TODO: validate payload, write ticket YAML, commit, TicketCache.put/1
    {:noreply, socket}
  end

  def handle_in("ticket:update", %{"id" => _id, "patch" => _patch}, socket) do
    # TODO: apply patch, commit, broadcast ticket:changed
    {:noreply, socket}
  end

  def handle_in("run:dispatch", %{"ticket_id" => _ticket_id, "cli" => _cli}, socket) do
    # TODO: Harmony.Dispatcher.dispatch/2
    {:noreply, socket}
  end

  def handle_in("run:cancel", %{"run_id" => _run_id}, socket) do
    # TODO: Harmony.Dispatcher.cancel/1
    {:noreply, socket}
  end
end
