defmodule Incrementer.Queue do
  @moduledoc """
  A GenServer implementation of a background queue, which manages SQL statements
  that bulk upsert new key-value pairs from the ETS table named `:cache` to a
  SQLite database named `:numbers`.

  This process is responsible for kicking off the initialization of both the ETS
  table as well as the queue of SQL statements. Every five seconds, it executes
  the oldest SQL statement in the queue to persist the data to the database, then
  it adds a new SQL statement to the queue based on the data currently in the
  ETS table, and finally it clears deletes objects from the ETS table that are
  older than 1 second.
  """

  use GenServer
  alias Incrementer.Cache

  @doc """
  Starts the GenServer process
  """
  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  # Callbacks

  @doc """
  Manages persistance of data to the database, cleanup of the ETS table, and
  adding new instructions to the queue.

  If there are instructions in the queue, this pops off the oldest instruction,
  executes the instruction to persist data to the database, removes objects from
  the ETS table that are older than 1 second, adds a new instruction to the queue
  based on the remaining objects in the ETS table, kicks off the scheduler to loop
  over this function in another 5 seconds, and returns the new queue.

  If the queue is empty, simply kicks off the scheduler to loop over this function
  in another 5 seconds, and returns the queue.
  """
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

  @doc """
  Initializes the ETS cache table and kicks off the scheduler, which sends the
  message `:work` to this process every 5 seconds.

  Returns an empty `:queue`.
  """
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
      time = System.monotonic_time()
      ets_statement = "INSERT OR REPLACE INTO numbers VALUES #{Cache.formatted_values}"
      Cache.cleanup(time)
      :queue.in(ets_statement, queue)
    else
      queue
    end
  end
end
