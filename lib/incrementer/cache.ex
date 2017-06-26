defmodule Incrementer.Cache do
  @moduledoc """
  Provides convenience functions for creating, reading, and cleaning up a
  public ETS table named `:cache`, which serves as our project's cache
  mechanism.
  """

  @doc """
  Initializes a public ETS table of type `set`, with the name `:cache`.
  """
  def create do
    :ets.new(
      :cache,
      [:named_table,
        :set,
        :public]
    )
  end

  @doc """
  Returns all existing objects in the `:cache` ETS table as a string of
  concatenated values, formatted for bulk insertion into a SQLite database.

  ## Examples

      iex> :ets.insert(:cache, {"key1", "value1", "timestamp"})
      iex> :ets.insert(:cache, {"key2", "value2", "timestamp"})
      iex> Incrementer.Cache.formatted_values()
      "(key1, value1), (key2, value2)"

  """
  def formatted_values do
    :cache
    |> :ets.tab2list
    |> Enum.map_join(", ", fn({k, v, _t}) -> "(#{k}, #{v})" end)
  end

  @doc """
  Evaluates whether the `:cache` ETS table contains any objects.

  Returns a boolean.

  ##Examples

      iex> Incrementer.Cache.has_values()
      false

      iex> :ets.insert(:cache, {"key", "value", "timestamp"})
      iex> Incrementer.Cache.has_values()
      true

  """
  def has_values do
    :ets.info(:cache)[:size] > 0
  end

  @doc """
  Receives a monotonic time in seconds and deletes objects from the `:cache` ETS
  table that are older than 1 second.

  Returns the number of objects deleted.
  """
  def cleanup(time) do
    # This match specification syntax follows the format of
    # [{Initial Pattern, Guard Clause, Returned Value}]. This is the output of
    # `:ets.fun2ms/1` where the guard clause checks for objects whose timestamps
    # are older than 1 second from the `time` argument. Because `:ets.fun2ms/1`
    # only accepts a single literal parameter and can't accept variables in its
    # guard clause, we need to pass it this literal syntax. For more information
    # see http://erlang.org/doc/man/ets.html#fun2ms-1 and http://learnyousomeerlang.com/ets
    match_spec = [{{:"$1", :"$2", :"$3"}, [{:>, {:-, time, :"$3"}, 1}], [true]}]

    :ets.select_delete(:cache, match_spec)
  end
end
