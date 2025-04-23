# Simple Agent

hello world

A showcase library demonstrating a simple coding agent implementation in Elixir. 

## Overview

Simple Agent is a lightweight Elixir application that:
- Implements a GenServer-based agent server for managing chat state
- Integrates with the Anthropic Claude API for natural language processing
- Provides a CLI interface for interactive conversations
- Supports tool definitions for extending agent capabilities

## Requirements

- Elixir ~> 1.15
- Anthropic API key (set as ANTHROPIC_API_KEY environment variable)

## Usage

1. Set your Anthropic API key:
```bash
export ANTHROPIC_API_KEY="your-api-key"
```

2. Start the agent:
```bash
mix escript.build
./simple_agent
```

## License

MIT License

