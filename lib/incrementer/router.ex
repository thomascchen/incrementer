defmodule Incrementer.Router do
  @moduledoc """
  Simple router that accepts a POST request at the "/increment" endpoint, with
  `key` and `value` parameters, where `key` is a string and `value` is an
  integer. A successful response body consists of a number that is the sum of
  the `value` parameter and all previously submitted values associated with
  this `key`.

  All other paths respond with a 404 status code.
  """

  use Plug.Router

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

    result = Incrementer.Server.increment(pid, {key, value})

    conn
    |> send_resp(200, Integer.to_string(result))
  end

  match _ do
    conn
    |> send_resp(404, "")
  end

  @doc """
  Starts the server on port 3333
  """
  def start_link do
    {:ok, _} = Plug.Adapters.Cowboy.http(Incrementer.Router, [], port: 3333)
  end
end
