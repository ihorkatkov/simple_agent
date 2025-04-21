defmodule SimpleAgent.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {SimpleAgent.Server,
       %{
         api_key: System.fetch_env!("ANTHROPIC_API_KEY"),
         tools: SimpleAgent.Tools.tool_definitions()
       }}
    ]

    opts = [strategy: :one_for_one, name: SimpleAgent.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
