
defmodule Incrementer.Queue do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  # Callbacks

  def handle_info(:work, state) do
    new_state = case :queue.out(state) do
      {{_value, statement}, new_queue} ->
        # IO.puts(statement)
        # prev = System.monotonic_time()
        Sqlitex.Server.exec(:numbers, statement)
        # next = System.monotonic_time()
        # diff = next - prev
        # time = System.convert_time_unit(diff, :native, :millisecond)
        # IO.inspect(time)

        new_queue
      _ ->
        # Queue is empty - restarting queue.
        state
    end

    synced_state = sync_ets(new_state)
    schedule_work()

    {:noreply, synced_state}
  end

  def init(_args) do
    :ets.new(
      :cache,
      [:named_table,
        :set,
        :public]
    )

    schedule_work()

    {:ok, :queue.new()}
  end

  # Private

  # defp initialize_queue do
  #   case :ets.tab2list(:cache) do
  #     [] ->
  #       :queue.new()
  #     _ ->
  #       sync_ets(:queue.new())
  #   end
  # end

  defp format_data({key, value}) do
    "(#{key}, #{value})"
  end

  # defp execute(statement) do
  #   Sqlitex.Server.exec(:numbers, statement)
  # end

  defp schedule_work do
    Process.send_after(self(), :work, 5000) # 5 seconds
  end

  defp sync_ets(statement_queue) do
    values = :ets.tab2list(:cache)
      |> Enum.map(fn(x) -> format_data(x) end)
      |> Enum.join(", ")

    ets_statement = "INSERT OR REPLACE INTO numbers VALUES #{values}"

    :ets.delete_all_objects(:cache)

    :queue.in(ets_statement, statement_queue)
  end
end
