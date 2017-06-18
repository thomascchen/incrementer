defmodule Incrementer.Cache do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [
      {:ets_table_name, :cache},
      {:log_limit, 1_000_000}
    ], opts)
  end

  # Callbacks

  def init(args) do
    [{:ets_table_name, ets_table_name}, {:log_limit, log_limit}] = args

    :ets.new(ets_table_name, [:named_table, :set, :public, {:write_concurrency, true}])

    {:ok, %{log_limit: log_limit, ets_table_name: ets_table_name}}
  end
end
