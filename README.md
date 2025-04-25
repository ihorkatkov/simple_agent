# Simple Agent

A showcase library demonstrating a simple coding agent implementation in Elixir, leveraging the Anthropic Claude API and the Multi-Context Processor (MCP) for tool usage.

## Overview

Simple Agent is a lightweight Elixir application that:
- Implements a chat loop for interacting with an AI model.
- Integrates with the Anthropic Claude API for natural language processing.
- Connects to a Multi-Context Processor (MCP) server via the `Hermes` library to enable the use of external tools through STDIO (e.g. tools available in other ecosystems)
- Provides a CLI interface for interactive conversations.
- Supports defining both local Elixir tools and utilizing tools exposed by the MCP.

## Requirements

- Node.js and `npx` (for running the MCP server)
- Anthropic API key (set as ANTHROPIC_API_KEY environment variable)

## Usage

The MCP server (`@upstash/context7-mcp`) is automatically started and managed by the Elixir application's supervision tree when the application starts. `npx` will handle downloading the MCP package if necessary.

1. Set your Anthropic API key:
```bash
export ANTHROPIC_API_KEY="your-api-key"
```

2. Build and start the agent:
```bash
mix escript.build
./simple_agent
```

## License

MIT License

