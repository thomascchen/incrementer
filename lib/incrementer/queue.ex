defmodule Incrementer.Queue do
  use GenServer
  alias Incrementer.Cache

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  # Callbacks

  def handle_info(:work, queue) do
    new_queue = case :queue.out(queue) do
      {{_value, statement}, remaining_queue} ->
        Sqlitex.Server.exec(:numbers, statement)
        remaining_queue
      _ ->
        queue
    end

    refreshed_queue = refresh(new_queue)
    schedule_work()

    {:noreply, refreshed_queue}
  end

  def init(_args) do
    Cache.init()
    schedule_work()
    {:ok, :queue.new()}
  end

  # Private

  defp schedule_work do
    Process.send_after(self(), :work, 5000) # 5 seconds
  end

  defp refresh(queue) do
    if Cache.values?() do
      Cache.cleanup()

      ets_statement = "INSERT OR REPLACE INTO numbers VALUES #{Cache.formatted_values}"
      :queue.in(ets_statement, queue)
    else
      queue
    end
  end
end
