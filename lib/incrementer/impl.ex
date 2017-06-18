defmodule Incrementer.Impl do
  use GenServer

  def start(key) do
    GenServer.start_link(__MODULE__, 0, name: key)
  end

  def increment(pid, {key, value}) do
    GenServer.call(pid, {:increment, {key, value}})
  end

  # def increment(pid, {key, value}) do
  #   GenServer.cast(pid, {:increment, {key, value}})
  # end

  # Callbacks

  def handle_call({:increment, {key, value}}, _from, state) do
    new_state = state + value

    # Sqlitex.Server.exec(
    #   :numbers,
    #   "INSERT OR REPLACE INTO numbers (key, value) VALUES ($1, $2)",
    #   bind: [key, new_state]
    # )

    :ets.insert(:cache, {key, new_state})

    {:reply, new_state, new_state}
  end

  # def handle_cast({:increment, {key, value}}, state) do
  #   new_state = state + value
  #
  #   # Sqlitex.Server.exec(
  #   #   :numbers,
  #   #   "INSERT OR REPLACE INTO numbers (key, value) VALUES ($1, $2)",
  #   #   bind: [key, new_state]
  #   # )
  #
  #   :ets.insert(:cache, {key, new_state})
  #
  #   {:noreply, new_state}
  # end
end
