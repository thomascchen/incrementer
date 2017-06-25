defmodule Incrementer.Server do
  @moduledoc """
  A GenServer, which takes a key-value pair, increments the value, and writes
  the key-value pair along with a timestamp to an ETS table with a name of :cache
  """

  use GenServer

  @doc """
  Starts a named GenServer process. Accepts a `key` argument, which is converted to
  an atom solely for the purpose of naming the process.

  Returns {:ok, pid}
  """
  def start(key) do
    name = String.to_atom(key)

    GenServer.start_link(__MODULE__, 0, name: name)
  end

  @doc """
  Receives the `pid` and a `{key, value}` tuple, and sends the message `:increment`
  to the `handle_call` callback function, along with the `{key, value}` tuple.
  """
  def increment(pid, {key, value}) do
    GenServer.call(pid, {:increment, {key, value}})
  end

  # Callbacks

  @doc """
  Converts the `value` argument from a string to an integer, increments the value,
  then inserts the object into the ETS table along with a timestamp.
  """
  def handle_call({:increment, {key, value}}, _from, state) do
    value = String.to_integer(value)
    new_state = state + value
    timestamp = System.monotonic_time()

    :ets.insert(:cache, {key, new_state, timestamp})

    {:reply, new_state, new_state}
  end
end
