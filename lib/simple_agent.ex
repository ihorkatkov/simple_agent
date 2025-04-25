defmodule SimpleAgent do
  @moduledoc """
  Documentation for `SimpleAgent`.
  """

  alias SimpleAgent.Conversation

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

  @doc """
  Starts the chat loop with the specified client and tools.
  """
  def run(client, tools) do
    IO.puts("Chat with Claude (use Ctrl‑C to quit)")
    loop(%Conversation{}, client, tools)
  end

  defp loop(conversation, client, tools) do
    case IO.gets("\e[94mYou\e[0m: ") do
      :eof ->
        # user sent EOF
        :ok

      raw_input ->
        user_input = String.trim(raw_input)

        conversation
        |> Conversation.add_user_message(user_input)
        |> handle_response(client, tools)
        |> loop(client, tools)
    end
  end

  @doc """
  Processes a user message, sends it to Claude, and handles any tool use.
  Returns {blocks, updated_conversation}.
  """
  def handle_response(conversation, client, tools) do
    # extract just the metadata for the API
    tool_defs = Enum.map(tools, &Map.take(&1, [:name, :description, :input_schema]))

    params = [
      model: "claude-3-7-sonnet-latest",
      system: @system_prompt,
      messages: conversation.messages,
      tools: tool_defs,
      tool_choice: %{type: "auto"}
    ]

    {:ok, response} = Anthropix.chat(client, params)
    %{"content" => content_blocks, "stop_reason" => stop_reason} = response
    conversation = Conversation.add_assistant_message(conversation, content_blocks)

    # Handle response based on stop_reason from Anthropic API
    # stop_reason can be one of:
    # - "end_turn": the model reached a natural stopping point
    # - "max_tokens": exceeded the requested max_tokens or the model's maximum
    # - "stop_sequence": one of the provided custom stop_sequences was generated
    # - "tool_use": the model invoked one or more tools
    case stop_reason do
      "tool_use" ->
        tool_result_blocks =
          Enum.reduce(content_blocks, [], fn block, acc ->
            case process_blocks(block, tools) do
              nil -> acc
              result -> acc ++ [result]
            end
          end)

        conversation
        |> Conversation.add_user_message(tool_result_blocks)
        |> handle_response(client, tools)

      _ ->
        Enum.each(content_blocks, &print_block/1)
        conversation
    end
  end

  defp process_blocks(%{"type" => "tool_use", "id" => id} = block, tools) do
    print_block(block)
    result = execute_tool(block, tools)

    %{
      "type" => "tool_result",
      "tool_use_id" => id,
      "content" => result
    }
  end

  defp process_blocks(block, _tools) do
    print_block(block)

    nil
  end

  defp execute_tool(%{"name" => name, "input" => input}, tools) do
    case Enum.find(tools, &(&1.name == name)) do
      %{function: fun} -> fun.(input)
      nil -> "tool not found"
    end
  end

  defp print_block(%{"type" => "text", "text" => text}) do
    IO.puts("\e[93mClaude\e[0m: #{text}")
  end

  defp print_block(%{"type" => "thinking", "text" => text}) do
    IO.puts("\e[96mClaude (thinking)\e[0m: #{text}")
  end

  defp print_block(%{"type" => "tool_use", "name" => name}) do
    IO.puts("\e[92mClaude is using tool\e[0m: #{name}")
  end

  defp print_block(_), do: :ok
end
