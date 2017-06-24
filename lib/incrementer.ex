defmodule Incrementer do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: Incrementer.Worker.start_link(arg1, arg2, arg3)
      # worker(Incrementer.Worker, [arg1, arg2, arg3]),
      # worker(Incrementer.Cache, []),
      worker(Sqlitex.Server, ["./numbers.db", [name: :numbers]]),
      worker(Incrementer.Queue, []),
      worker(Incrementer.Router, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Incrementer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
