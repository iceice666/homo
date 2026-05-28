defmodule Harmony.TicketCache do
  use GenServer

  @table :harmony_tickets

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Derived projection of git-HEAD ticket state. Never treat as authoritative — always
  # rebuild from `git show HEAD:<path>` after a post-commit hook fires.

  def get(ticket_id) do
    case :ets.lookup(@table, ticket_id) do
      [{^ticket_id, ticket}] -> {:ok, ticket}
      [] -> :error
    end
  end

  def put(ticket) do
    :ets.insert(@table, {ticket["id"], ticket})
    :ok
  end

  def all do
    :ets.tab2list(@table) |> Enum.map(fn {_id, ticket} -> ticket end)
  end

  # GenServer

  @impl true
  def init(_) do
    :ets.new(@table, [:named_table, :set, :public, read_concurrency: true])
    {:ok, %{}}
  end
end
