defmodule Incrementer.Router do
  use Plug.Router

  plug Plug.Parsers, parsers: [:urlencoded]
  plug :match
  plug :dispatch

  get "/" do
    conn
    |> send_resp(200, "get!")
  end

  post "/increment" do
    %{"key" => key, "value" => value} = conn.params
    key = String.to_atom(key)
    value = String.to_integer(value)

    pid = case GenServer.whereis(key) do
      nil ->
        {:ok, process} = Incrementer.Handler.start(key)
        process
      _ ->
        key
    end

    response = Incrementer.Handler.increment(pid, value)

    conn
    |> send_resp(200, Integer.to_string(response))
  end

  match _ do
    conn
    |> send_resp(200, "other!")
  end

  def start_link do
    {:ok, _} = Plug.Adapters.Cowboy.http(Incrementer.Router, [], port: 3333)
  end
end
