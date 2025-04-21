defmodule SimpleAgent do
  @moduledoc """
  Documentation for `SimpleAgent`.
  """

  alias Anthropix

  @system_prompt """
  Act as an expert senior Elixir engineer. You will work with a stack that includes Elixir, Phoenix, Docker, PostgreSQL, Tailwind CSS, Sobelow, Credo, Ecto, ExUnit, Plug, Phoenix LiveView, Phoenix LiveDashboard, Gettext, Jason, Swoosh, Finch, DNS Cluster, File System Watcher, Release Please, and ExCoveralls.

  When writing code, first thoroughly consider any considerations or requirements to ensure all aspects are covered. Then, proceed to write the code only after this detailed reasoning.

  After completing a response, provide three follow-up questions as if I am asking you. Format these as **Q1**, **Q2**, and **Q3**. These should be thought-provoking questions that delve deeper into the original topic.

  # Output Format

  - Provide detailed reasoning before executing any coding solution.
  - Return code snippets followed by a structured section with follow-up questions.
  - When responding with commit messages, follow the conventional structure provided.

  # Examples

  ## Code Response Example:
  Reason through the problem considering factors such as [factors].
  ```elixir
  # Include relevant Elixir code here
  ```
  **Q1:** How does this approach affect [specific concern]?
  **Q2:** What potential impacts should be considered regarding [another concern]?
  **Q3:** What are alternative methods to achieve [aspect]?

  (Example should be adapted to realistic scenarios in your domain using the stack you have)

  Use clear, direct language and ensure responses align with the latest updates in technology and practices to maintain relevance. Be brutally honest!
  """

  def run(client, tools) do
    IO.puts("Chat with Claude (use Ctrl‑C to quit)")
    loop(client, tools, [])
  end

  defp loop(client, tools, conversation) do
    case IO.gets("\e[94mYou\e[0m: ") do
      :eof ->
        # user sent EOF
        :ok

      raw_input ->
        user_input = String.trim(raw_input)
        convo1 = conversation ++ [%{role: "user", content: user_input}]
        {blocks, convo2} = handle_response(client, tools, convo1)

        Enum.each(blocks, &print_block/1)
        loop(client, tools, convo2)
    end
  end

  def handle_response(client, tools, conversation) do
    # extract just the metadata for the API
    tool_defs = Enum.map(tools, &Map.take(&1, [:name, :description, :input_schema]))

    params = [
      model: "claude-3-7-sonnet-latest",
      system: @system_prompt,
      messages: conversation,
      tools: tool_defs,
      tool_choice: %{type: "auto"}
    ]

    {:ok, %{"content" => content_blocks}} = Anthropix.chat(client, params)
    conversation = conversation ++ [%{role: "assistant", content: content_blocks}]

    case Enum.find_index(content_blocks, &(&1["type"] == "tool_use")) do
      nil ->
        # no tool needed → final assistant response
        {content_blocks, conversation}

      tool_use_index ->
        # Print any text blocks that appear before the tool_use block
        content_blocks
        |> Enum.take(tool_use_index)
        |> Enum.each(&print_block/1)

        # Get the tool_use block
        tool_use = Enum.at(content_blocks, tool_use_index)

        # Execute the requested tool
        IO.puts("\e[92mtool\e[0m: #{tool_use["name"]}(#{Jason.encode!(tool_use["input"])})")
        result = execute_tool(tool_use, tools)

        # wrap result in a tool_result block and re‑invoke Claude
        tool_result_block = %{
          "type" => "tool_result",
          "tool_use_id" => tool_use["id"],
          "content" => result
        }

        new_convo = conversation ++ [%{role: "user", content: [tool_result_block]}]
        handle_response(client, tools, new_convo)
    end
  end

  defp execute_tool(%{"name" => name, "input" => input}, tools) do
    case Enum.find(tools, &(&1.name == name)) do
      %{function: fun} -> fun.(input)
      _ -> "tool not found"
    end
  end

  defp print_block(%{"type" => "text", "text" => text}) do
    IO.puts("\e[93mClaude\e[0m: #{text}")
  end

  defp print_block(_), do: :ok
end
