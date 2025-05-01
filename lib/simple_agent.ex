defmodule SimpleAgent do
  @moduledoc """
  Documentation for `SimpleAgent`.
  """

  alias SimpleAgent.Conversation

  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Chains.LLMChain
  alias LangChain.Message

  require Logger

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
  def run do
    IO.puts("Chat with Simple Coding Agent (use Ctrl‑C to quit)")

    chain =
      LLMChain.new!(%{
        llm:
          ChatOpenAI.new!(%{
            model: "gpt-4.1-2025-04-14",
            temperature: 1,
            verbose_api: false
          }),
        verbose: false
      })
      |> LLMChain.add_callback(%{on_message_processed: &print_message/2})
      |> LLMChain.add_message(Message.new_system!(@system_prompt))
      |> LLMChain.add_tools(SimpleAgent.Tools.tool_definitions())

    loop(chain)
  end

  defp loop(chain) do
    case IO.gets("\e[94mYou\e[0m: ") do
      :eof ->
        # user sent EOF
        :ok

      raw_input ->
        user_input = String.trim(raw_input)

        result =
          chain
          |> LLMChain.add_message(Message.new_user!(user_input))
          |> LLMChain.run(mode: :while_needs_response)

        case result do
          {:ok, chain} ->
            loop(chain)

          {:error, error} ->
            IO.puts("\e[91mError: #{inspect(error)}\e[0m")
            loop(chain)
        end
    end
  end

  defp print_message(chain, %LangChain.Message{content: content} = message) do
    case content do
      content when is_list(content) ->
        Enum.each(content, &print_block(chain, &1))

      _ ->
        IO.inspect(message)
    end
  end

  defp print_messages(_chain, message) do
    Logger.warning("Unknown message type: #{inspect(message)}")

    :ok
  end

  defp print_block(_chain, %LangChain.Message.ContentPart{type: :text, content: text}) do
    IO.puts("\e[93mSimple Coding Agent\e[0m: #{text}")
  end

  defp print_block(_chain, %LangChain.Message.ContentPart{type: :thinking, content: text}) do
    IO.puts("\e[96mSimple Coding Agent (thinking)\e[0m: #{text}")
  end

  defp print_block(_chain, block) do
    Logger.warning("Unknown message type: #{inspect(block)}")
    IO.puts("\e[95mSimple Coding Agent\e[0m: #{inspect(block)}")
  end
end
