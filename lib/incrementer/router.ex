defmodule MoodRingSup.Router do
  use Plug.Router
  require Plug.Conn.Query

  plug :match
  plug :dispatch

  get "/" do
    conn
    |> send_resp(200, "wow!")
  end

  post "/increment" do
    {:ok, body, _} = read_body(conn);
    %{"key" => key, "value" => value} = Plug.Conn.Query.decode(body)
    IO.inspect(key)
    IO.inspect(String.to_integer(value))

    conn
    |> send_resp(200, 'success!')
  end

  match _ do
    conn
    |> send_resp(200, "woooow!")
  end

  def start_link do
    {:ok, _} = Plug.Adapters.Cowboy.http(MoodRingSup.Router, [], port: 3333)
  end
end
