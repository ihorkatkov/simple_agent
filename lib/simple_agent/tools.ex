defmodule SimpleAgent.Tools do
  @moduledoc """
  Defines tool metadata (name/description/input_schema) for Claude
  and implements the actual file‑system functions.
  """

  # -- Tool definitions sent to Claude:
  @read_file %{
    name: "read_file",
    description: "Read the contents of a given relative file path. \
       Use when you want to see what's inside a file; not for directories.",
    input_schema: %{
      "type" => "object",
      "properties" => %{
        "path" => %{"type" => "string", "description" => "Relative file path"}
      },
      "required" => ["path"]
    },
    function: &SimpleAgent.Tools.read_file/1
  }

  @list_files %{
    name: "list_files",
    description: "List files and directories at a given path. \
       If no path is provided, lists the current directory.",
    input_schema: %{
      "type" => "object",
      "properties" => %{
        "path" => %{
          "type" => "string",
          "description" => "Optional relative path to list; defaults to current dir"
        }
      }
      # no required → path is optional
    },
    function: &SimpleAgent.Tools.list_files/1
  }

  @edit_file %{
    name: "edit_file",
    description: """
    Make edits to a text file.

    Replaces `old_str` with `new_str` in the given file. \
    `old_str` and `new_str` must differ. \
    If the file doesn't exist and `old_str` is empty, it will be created.
    """,
    input_schema: %{
      "type" => "object",
      "properties" => %{
        "path" => %{"type" => "string", "description" => "File path"},
        "old_str" => %{"type" => "string", "description" => "Text to replace"},
        "new_str" => %{"type" => "string", "description" => "Replacement text"}
      },
      "required" => ["path", "old_str", "new_str"]
    },
    function: &SimpleAgent.Tools.edit_file/1
  }

  @doc "Expose a list of all tools (with both metadata & function)"
  def tool_definitions do
    local_tools = [@list_files, @read_file, @edit_file]
    {:ok, %Hermes.MCP.Response{} = response} = Hermes.Client.list_tools(SimpleAgent.MCPClient)

    mcp_tools =
      Enum.map(response.result["tools"], fn tool ->
        %{
          name: tool["name"],
          description: tool["description"],
          input_schema: tool["inputSchema"],
          function: &SimpleAgent.Tools.mcp_tool_function(tool["name"], &1)
        }
      end)

    local_tools ++ mcp_tools
  end

  def mcp_tool_function(tool, input) do
    {:ok, %Hermes.MCP.Response{} = response} =
      Hermes.Client.call_tool(SimpleAgent.MCPClient, tool, input)

    response.result
    |> Map.get("content")
    |> Enum.map(& &1["text"])
    |> Enum.join("\n")
  end

  # -- Actual implementations:

  def read_file(%{"path" => path}) do
    case File.read(path) do
      {:ok, content} -> content
      {:error, reason} -> "Error reading file: #{:file.format_error(reason)}"
    end
  end

  def list_files(input) do
    dir = Map.get(input, "path", ".")

    files =
      dir
      |> File.ls!()
      |> Enum.map(fn f ->
        if File.dir?(Path.join(dir, f)), do: f <> "/", else: f
      end)
      |> Enum.join("\n")

    files
  rescue
    err -> "Error listing files: #{inspect(err)}"
  end

  def edit_file(%{"path" => path, "old_str" => old, "new_str" => new}) do
    case File.read(path) do
      {:ok, content} ->
        new_content = String.replace(content, old, new)

        cond do
          content == new_content and old != "" ->
            "old_str not found in file"

          true ->
            File.write!(path, new_content)
            "OK"
        end

      {:error, :enoent} when old == "" ->
        # create new file
        path |> Path.dirname() |> File.mkdir_p!()
        File.write!(path, new)
        "File created: #{path}"

      {:error, reason} ->
        "Error editing file: #{:file.format_error(reason)}"
    end
  end
end
