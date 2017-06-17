defmodule Incrementer.GenServer do
  use GenServer

  def start(key) do
    GenServer.start_link(__MODULE__, 0, name: key)
  end

  def increment(pid, value) do
    GenServer.call(pid, {:increment, value})
  end

  # Callbacks

  def handle_call({:increment, value}, _from, state) do
    new_state = state + value

    {:reply, new_state, new_state}
  end
end
