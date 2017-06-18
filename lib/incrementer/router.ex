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

    pid = case Incrementer.Impl.start(name) do
      {:ok, process} ->
        process
      {:error, {:already_started, process}} ->
        process
    end

    Incrementer.Impl.increment(pid, {key, value})

    conn
    |> send_resp(200, "")
  end

  match _ do
    conn
    |> send_resp(200, "other!")
  end

  def start_link do
    {:ok, _} = Plug.Adapters.Cowboy.http(Incrementer.Router, [], port: 3333)
  end
end
