defmodule Incrementer.Server do
  use GenServer

  def start(key) do
    name = String.to_atom(key)

    GenServer.start_link(__MODULE__, 0, name: name)
  end

  def increment(pid, {key, value}) do
    GenServer.call(pid, {:increment, {key, value}})
  end

  # Callbacks

  def handle_call({:increment, {key, value}}, _from, state) do
    value = String.to_integer(value)
    new_state = state + value
    timestamp = System.monotonic_time()

    :ets.insert(:cache, {key, new_state, timestamp})

    {:reply, new_state, new_state}
  end
end
