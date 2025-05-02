defmodule SimpleAgent.CLI do
  def main(_args) do
    ping()

    SimpleAgent.run()
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
