defmodule SimpleAgent.ToolsTest do
  use ExUnit.Case

  setup do
    # Create a temporary directory for our tests
    tmp_dir = Path.join(System.tmp_dir!(), "simple_agent_tools_test_#{:rand.uniform(1000)}")
    File.mkdir_p!(tmp_dir)

    # Create a test file for editing
    test_file = Path.join(tmp_dir, "test_file.txt")
    File.write!(test_file, "Hello, world!")

    on_exit(fn ->
      # Clean up after tests
      File.rm_rf!(tmp_dir)
    end)

    %{tmp_dir: tmp_dir, test_file: test_file}
  end

  test "tool_definitions returns a list of tools", %{} do
    tools = SimpleAgent.Tools.tool_definitions()

    assert is_list(tools)
    assert length(tools) == 3

    # Check that each tool has the required fields
    Enum.each(tools, fn tool ->
      assert Map.has_key?(tool, :name)
      assert Map.has_key?(tool, :description)
      assert Map.has_key?(tool, :input_schema)
      assert Map.has_key?(tool, :function)
      assert is_function(tool.function, 1)
    end)

    # Check for specific tools
    assert Enum.any?(tools, &(&1.name == "read_file"))
    assert Enum.any?(tools, &(&1.name == "list_files"))
    assert Enum.any?(tools, &(&1.name == "edit_file"))
  end

  test "read_file returns file content", %{test_file: test_file} do
    result = SimpleAgent.Tools.read_file(%{"path" => test_file})
    assert result == "Hello, world!"
  end

  test "read_file handles error for non-existent file", %{tmp_dir: tmp_dir} do
    non_existent = Path.join(tmp_dir, "non_existent.txt")
    result = SimpleAgent.Tools.read_file(%{"path" => non_existent})
    assert result =~ "Error reading file"
  end

  test "list_files lists directory contents", %{tmp_dir: tmp_dir} do
    # Create additional files and directories for testing
    File.write!(Path.join(tmp_dir, "another_file.txt"), "content")
    File.mkdir_p!(Path.join(tmp_dir, "subdirectory"))

    result = SimpleAgent.Tools.list_files(%{"path" => tmp_dir})

    assert result =~ "test_file.txt"
    assert result =~ "another_file.txt"
    assert result =~ "subdirectory/"
  end

  test "edit_file replaces content in existing file", %{test_file: test_file} do
    result =
      SimpleAgent.Tools.edit_file(%{
        "path" => test_file,
        "old_str" => "Hello",
        "new_str" => "Goodbye"
      })

    assert result == "OK"
    assert File.read!(test_file) == "Goodbye, world!"
  end

  test "edit_file creates new file when old_str is empty", %{tmp_dir: tmp_dir} do
    new_file = Path.join(tmp_dir, "new_file.txt")

    result =
      SimpleAgent.Tools.edit_file(%{
        "path" => new_file,
        "old_str" => "",
        "new_str" => "New content"
      })

    assert result =~ "File created"
    assert File.read!(new_file) == "New content"
  end

  test "edit_file reports when old_str is not found", %{test_file: test_file} do
    result =
      SimpleAgent.Tools.edit_file(%{
        "path" => test_file,
        "old_str" => "NotInFile",
        "new_str" => "Replacement"
      })

    assert result == "old_str not found in file"
    assert File.read!(test_file) == "Hello, world!"
  end
end
