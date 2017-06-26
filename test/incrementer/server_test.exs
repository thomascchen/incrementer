defmodule Incrementer.ServerTest do
  use ExUnit.Case, async: true
  alias Incrementer.Server
  doctest Server

  setup_all do
    on_exit fn ->
      :ets.delete_all_objects(:cache)
    end
  end

  test "start/1 starts a registered process" do
    {:ok, pid} = Server.start("pid")
    assert(Process.whereis(:pid) == pid)
  end

  test "increment/2 increments a number" do
    Server.start("pid")
    result = Server.increment(:pid, {"pid", "1"})
    assert(result == 1)

    result2 = Server.increment(:pid, {"pid", "2"})
    assert(result2 == 3)
  end

  test "increment/3 inserts object into ETS table" do
    Server.start("pid")
    Server.increment(:pid, {"pid", "1"})
    [{"pid", value, _timestamp}] = :ets.lookup(:cache, "pid")
    assert(value == 1)
  end
end
