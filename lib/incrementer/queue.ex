
defmodule Incrementer.Queue do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :queue.new())
  end

  # Callbacks

  def handle_info(:work, state) do
    new_state = case :queue.out(state) do
      {{_value, statement}, new_queue} ->
        Sqlitex.Server.exec(:numbers, statement)
        new_queue
      _ ->
        state
    end

    updated_state = sync_ets(new_state)
    schedule_work()

    {:noreply, updated_state}
  end

  def init(arg) do
    :ets.new(
      :cache,
      [:named_table,
        :set,
        :public]
    )

    schedule_work()

    {:ok, arg}
  end

  # Private

  defp clean_ets(sync_time) do
    match_spec =[{{:"$1", :"$2", :"$3"}, [{:>, {:-, sync_time, :"$3"}, 1000000000}], [true]}]

    :ets.select_delete(:cache, match_spec)
  end

  defp format_data({key, value, _timestamp}) do
    "(#{key}, #{value})"
  end

  defp schedule_work do
    Process.send_after(self(), :work, 5000) # 5 seconds
  end

  defp sync_ets(statement_queue) do
    sync_time = System.monotonic_time()

    values = :ets.tab2list(:cache)
      |> Enum.map(fn(x) -> format_data(x) end)
      |> Enum.join(", ")

    if String.length(values) > 0 do
      clean_ets(sync_time)

      ets_statement = "INSERT OR REPLACE INTO numbers VALUES #{values}"

      :queue.in(ets_statement, statement_queue)
    else
      statement_queue
    end
  end
end
