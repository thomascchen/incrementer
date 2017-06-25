defmodule Incrementer.Cache do
  def init do
    :ets.new(
      :cache,
      [:named_table,
        :set,
        :public]
    )
  end

  def formatted_values do
    :cache
      |> :ets.tab2list
      |> Enum.map(fn({k, v, _t}) -> "(#{k}, #{v})" end)
      |> Enum.join(", ")
  end

  def values? do
    String.length(formatted_values()) > 0
  end

  def cleanup do
    time = System.monotonic_time()
    match_spec = [{{:"$1", :"$2", :"$3"}, [{:>, {:-, time, :"$3"}, 1_000_000_000}], [true]}]

    :ets.select_delete(:cache, match_spec)
  end
end
