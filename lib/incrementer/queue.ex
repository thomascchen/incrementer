defmodule Incrementer.Queue do
  @moduledoc """
  A simple GenServer implementation of a background scheduler, which queues up
  and executes SQL statements that bulk upsert objects from the `:cache` ETS
  table to a SQLite database named `:numbers`.

  This process is responsible for initializing the `:cache` ETS table and an
  empty queue. Every five seconds, it executes the oldest SQL statement in the
  queue to persist the data to the database, then it adds a new SQL statement to
  the queue based on the data currently in the ETS table, and finally it deletes
  objects from the ETS table that are older than 1 second.
  """

  use GenServer
  alias Incrementer.Cache

  @doc """
  Starts the process with an initial state of an empty `:queue`.
  """
  def start_link do
    GenServer.start_link(__MODULE__, :queue.new())
  end

  # Callbacks

  @doc """
  Manages data persistance, cleanup of the ETS table, and adding new SQL
  statements to the queue.

  If there are statements in the queue, this function pops off the oldest
  statement, executes it to persist data to the database, removes objects from
  the ETS table that are older than 1 second, adds a new instruction to the
  queue based on the remaining objects in the ETS table, kicks off the scheduler
  to loop over this function in another 5 seconds, and returns the new queue.

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

    schedule_work()

    {:noreply, refresh(new_queue)}
  end

  @doc """
  Initializes the ETS cache table and kicks off the scheduler, which sends the
  message `:work` to this process every 5 seconds.
  """
  def init(initial_queue) do
    Cache.create()
    schedule_work()
    {:ok, initial_queue}
  end

  # Private

  defp schedule_work do
    Process.send_after(self(), :work, 5000) # 5 seconds
  end

  defp refresh(queue) do
    if Cache.has_values() do
      time = System.monotonic_time(:second)
      ets_statement = "INSERT OR REPLACE INTO numbers VALUES #{Cache.formatted_values}"
      Cache.cleanup(time)
      :queue.in(ets_statement, queue)
    else
      queue
    end
  end
end
