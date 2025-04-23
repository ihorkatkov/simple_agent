defmodule SimpleAgent.Server do
  @moduledoc """
  A GenServer that manages our Claude chat state & tools,
  handles user input, invokes Claude + tools, and prints responses.
  """

  use GenServer
  require Logger

  ## Client API

  @doc """
  Starts the chat server under this process.
  Expects opts: %{api_key: "...", tools: [...]}.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Send raw user input (a line) to the chat server."
  def send_user_input(line) do
    GenServer.call(__MODULE__, {:user_input, line}, 30_000)
  end

  ## Server Callbacks

  @impl true
  def init(%{api_key: api_key, tools: tools} = _opts) do
    client = Anthropix.init(api_key)
    state = %{client: client, tools: tools, conversation: []}
    {:ok, state}
  end

  @impl true
  def handle_call({:user_input, raw}, _from, %{conversation: conv} = state) do
    user_msg = String.trim(raw)
    convo1 = conv ++ [%{role: "user", content: user_msg}]

    response =
      SimpleAgent.handle_response(
        state.client,
        state.tools,
        convo1
      )

    case response do
      {:error, _reason} = error ->
        Logger.error(error)
        {:reply, error, state}

      {blocks, convo2} ->
        Enum.each(blocks, &print_block/1)
        {:reply, :ok, %{state | conversation: convo2}}
    end
  end

  ## Helpers

  @doc """
  Formats and prints a block of content from Claude.
  """
  def print_block(%{"type" => "text", "text" => text}) do
    IO.puts("\e[93mClaude\e[0m: #{text}")
  end

  def print_block(_), do: :ok
end
