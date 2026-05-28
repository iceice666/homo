defmodule HarmonyTest do
  use ExUnit.Case

  test "TicketCache put and get" do
    ticket = %{"id" => "test-ticket", "title" => "Test", "status" => "pitched"}
    :ok = Harmony.TicketCache.put(ticket)
    assert {:ok, ^ticket} = Harmony.TicketCache.get("test-ticket")
  end

  test "TicketCache returns error for missing ticket" do
    assert :error = Harmony.TicketCache.get("nonexistent")
  end
end
