defmodule Incrementer.Router do
  use Plug.Router
  require Logger

  plug Plug.Parsers, parsers: [:urlencoded]
  plug :match
  plug :dispatch

  post "/increment" do
    %{"key" => key, "value" => value} = conn.params

    pid = case Incrementer.Server.start(key) do
      {:ok, process} ->
        process
      {:error, {:already_started, process}} ->
        process
    end

    Incrementer.Server.increment(pid, {key, value})

    conn
    |> send_resp(200, "success")
  end

  @doc """
  Starts the server on port 3333
  """
  def start_link do
    {:ok, _} = Plug.Adapters.Cowboy.http(Incrementer.Router, [], port: 3333)
  end
end
