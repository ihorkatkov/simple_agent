defmodule SimpleAgent.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    api_key =
      System.get_env("ANTHROPIC_API_KEY") ||
        Mix.raise("Please set ANTHROPIC_API_KEY in your environment")

    children = [
      {SimpleAgent.Server,
       %{
         api_key: api_key,
         tools: SimpleAgent.Tools.tool_definitions()
       }}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SimpleAgent.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
