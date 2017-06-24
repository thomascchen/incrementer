defmodule Incrementer.Cache do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [
      {:ets_table_name, :cache}
    ])
  end

  # Callbacks

  def init(args) do
    [{:ets_table_name, ets_table_name}] = args

    :ets.new(
      ets_table_name,
      [:named_table,
        :set,
        :public,
        {:read_concurrency, true},
        {:write_concurrency, true}]
    )

    {:ok, %{ets_table_name: ets_table_name}}
  end
end
