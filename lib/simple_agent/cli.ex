defmodule SimpleAgent.CLI do
  def main(_args) do
    ping()

    api_key =
      System.fetch_env!("ANTHROPIC_API_KEY")

    client = Anthropix.init(api_key)
    tools = SimpleAgent.Tools.tool_definitions()

    SimpleAgent.run(client, tools)
  end

  defp ping() do
    case Hermes.Client.ping(SimpleAgent.MCPClient) do
      :pong ->
        IO.puts("Received Pong from MCP")

      {:error, _reason} ->
        ping()
    end
  end
end
