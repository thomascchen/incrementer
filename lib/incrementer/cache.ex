defmodule Incrementer.Cache do
  @moduledoc """
  Provides convenience functions for creating, reading, and cleaning up an
  ETS table, which serves as the application's cache mechanism.
  """

  @doc """
  Initializes a public ETS table of type `set`, with name `:cache`.
  """
  def init do
    :ets.new(
      :cache,
      [:named_table,
        :set,
        :public]
    )
  end

  @doc """
  Returns all key value pairs in ETS table with name :cache as a single string
  formatted for bulk insertion into a SQLite database.

  ## Examples

      iex> Incrementer.Cache.values()
      "(key1, value1), (key2, value2), (key3, value3) ..."

  """
  def formatted_values do
    :cache
      |> :ets.tab2list
      |> Enum.map(fn({k, v, _t}) -> "(#{k}, #{v})" end)
      |> Enum.join(", ")
  end

  @doc """
  Evaluates whether ETS table with name `:cache` contains any objects.

  Returns a boolean (true or false)
  """
  def values? do
    String.length(formatted_values()) > 0
  end

  @doc """
  Deletes objects from ETS table with name `:cache` that are older than 1 second

  Returns the number of objects deleted
  """
  def cleanup(time) do
    # This match specification syntax follows the format of
    # [{Initial Pattern, Guard Clause, Returned Value}]. This is the output of
    # `:ets.fun2ms/1` where the guard clause checks for objects whose timestamps
    # are older than 1 second from the `time` argument. Because `:ets.fun2ms/1`
    # only accepts a single literal parameter and can't accept variables in its
    # guard clause, we need to pass it this literal syntax. For more information
    # see http://erlang.org/doc/man/ets.html#fun2ms-1 and http://learnyousomeerlang.com/ets
    match_spec = [{{:"$1", :"$2", :"$3"}, [{:>, {:-, time, :"$3"}, 1_000_000_000}], [true]}]

    :ets.select_delete(:cache, match_spec)
  end
end
