import Config

config :logger, level: :debug

config :langchain, openai_key: System.fetch_env!("OPENAI_API_KEY")
