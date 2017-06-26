defmodule Incrementer.CacheTest do
  use ExUnit.Case, async: true
  alias Incrementer.Cache
  doctest Cache

  setup do
    on_exit fn ->
      :ets.delete_all_objects(:cache)
    end
  end

  test "formatted_values/0 returns empty string when ETS table is empty" do
    assert(Cache.formatted_values() == "")
  end

  test "cleanup/0 deletes objects in ETS table older than 1 second" do
    timestamp = System.monotonic_time(:second)

    :ets.insert(:cache, {"key1", "value1", timestamp})
    :ets.insert(:cache, {"key2", "value2", timestamp + 1})

    num = Cache.cleanup(timestamp + 2)

    assert(num == 1)
    assert(:ets.lookup(:cache, "key1") == [])
    assert(:ets.lookup(:cache, "key2") == [{"key2", "value2", timestamp + 1}])
  end
end
