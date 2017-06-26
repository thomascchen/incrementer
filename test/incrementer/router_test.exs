defmodule Incrementer.RouterTest do
  use ExUnit.Case
  use Plug.Test
  alias Incrementer.Router

  @opts Router.init([])

  test "post /increment returns incremented value" do
    conn = conn(:post, "/increment", "key=a&value=1")
      |> put_req_header("content-type", "application/x-www-form-urlencoded")
      |> Router.call(@opts)

    {status, _headers, body} = sent_resp(conn)

    assert(status == 200)
    assert(body == "1")
  end

  test "get / returns 404" do
    response = conn(:get, "/")
      |> Router.call(@opts)

    assert(response.status == 404)
  end
end
