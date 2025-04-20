defmodule SimpleAgentTest do
  use ExUnit.Case
  doctest SimpleAgent

  test "greets the world" do
    assert SimpleAgent.hello() == :world
  end
end
