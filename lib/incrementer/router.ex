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
    name = String.to_atom(key)
    value = String.to_integer(value)

    pid = case GenServer.whereis(name) do
      nil ->
        {:ok, process} = Incrementer.GenServer.start(name)
        process
      _ ->
        name
    end

    response = Incrementer.GenServer.increment(pid, {key, value})

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
