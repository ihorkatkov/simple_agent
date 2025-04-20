defmodule SimpleAgent.CLI do
  def main(_args) do
    api_key =
      System.fetch_env!("ANTHROPIC_API_KEY")

    client = Anthropix.init(api_key)
    tools = SimpleAgent.Tools.tool_definitions()

    SimpleAgent.run(client, tools)
  end
end
