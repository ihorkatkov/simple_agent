defmodule SimpleAgent.Conversation do
  @moduledoc """
  Convenience functions for managing a conversation.
  """

  defstruct messages: []

  @doc """
  Add a user message to the conversation.
  """
  def add_user_message(conversation, content) do
    %{conversation | messages: conversation.messages ++ [%{role: "user", content: content}]}
  end

  @doc """
  Add an assistant message to the conversation.
  """
  def add_assistant_message(conversation, content) do
    %{conversation | messages: conversation.messages ++ [%{role: "assistant", content: content}]}
  end
end
