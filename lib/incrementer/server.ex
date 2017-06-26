defmodule Incrementer.Server do
  @moduledoc """
  A GenServer, which takes a key-value pair, increments the value, and writes
  the key-value pair along with a timestamp to an ETS table named `:cache`.
  """

  use GenServer

  @doc """
  Starts a named GenServer process. Accepts a `key` argument, which is converted to
  an atom solely for the purpose of naming the process.

  Returns `{:ok, pid}`.
  """
  def start(key) do
    name = String.to_atom(key)

    GenServer.start_link(__MODULE__, 0, name: name)
  end

  @doc """
  Receives a `pid` and a `{key, value}` tuple. Expects the `key` to be a string
  and `value` to be a string representation of an integer. Sends the message
  `:increment` to the `handle_call` callback function, along with the
  `{key, value}` tuple.

  Returns the incremented value as an integer.
  """
  def increment(pid, {key, value}) do
    GenServer.call(pid, {:increment, {key, value}})
  end

  # Callbacks

  @doc """
  Converts the `value` argument from a string to an integer, increments the
  value, then inserts the object into the `:cache` ETS table along with a
  timestamp.

  The incremented value is returned and set as the new state.
  """
  def handle_call({:increment, {key, value}}, _from, state) do
    value = String.to_integer(value)
    new_state = state + value
    timestamp = System.monotonic_time(:second)

    :ets.insert(:cache, {key, new_state, timestamp})

    {:reply, new_state, new_state}
  end
end
