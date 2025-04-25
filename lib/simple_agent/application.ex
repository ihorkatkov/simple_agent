defmodule SimpleAgent.Application do
  @moduledoc false

  use Application

  @mcp_client_name SimpleAgent.MCPClient

  @impl true
  def start(_type, _args) do
    mcp_server_command = "npx"
    mcp_server_args = ["-y", "@upstash/context7-mcp@latest"]

    children = [
      {Hermes.Transport.STDIO,
       [
         # Name for the transport process
         name: SimpleAgent.MCPTransport,
         client: @mcp_client_name,
         command: mcp_server_command,
         args: mcp_server_args
       ]},
      {Hermes.Client,
       [
         name: @mcp_client_name,
         transport: [layer: Hermes.Transport.STDIO, name: SimpleAgent.MCPTransport],
         client_info: %{
           "name" => "SimpleAgent",
           "version" => "0.1.0"
         },
         capabilities: %{
           "sampling" => %{}
         }
       ]}
    ]

    opts = [strategy: :one_for_one, name: SimpleAgent.Supervisor]
    result = Supervisor.start_link(children, opts)

    result
  end
end
