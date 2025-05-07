# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Chat.Repo.insert!(%Chat.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Chat.Repo
alias Chat.Models.{ModelProvider, Model}

provider =
  %ModelProvider{
    name: "OpenRouter",
    url: "https://openrouter.ai/api/v1",
    key: System.get_env("OPENROUTER_KEY")
  }
  |> Repo.insert!()

%Model{
  id: 42,
  public_id: Chat.PublicId.generate("m"),
  model_provider_id: provider.id,
  identifier: "google/gemini-2.0-flash-lite-001",
  vendor: "Google",
  name: "Gemini 2.0 Flash Lite",
  cost: 5,
  enabled: true,
  context_length: 32_000,
  max_tokens: 512
}
|> Repo.insert!()

[
  {"meta-llama/llama-3.2-1b-instruct", "Llama 3.2 1b"},
  {"liquid/lfm-7b", "Luquid LFM 7b"},
  {"qwen/qwen2.5-coder-7b-instruct", "Qwen 2.5 Coder 7b"},
  {"google/gemma-3-4b-it", "Gemma 3 4b"},
  {"deepseek/deepseek-r1-distill-llama-8b", "DeepSeek R1, Llama distill"}
]
|> Enum.each(fn {identifier, name} ->
  %Model{
    public_id: Chat.PublicId.generate("m"),
    model_provider_id: provider.id,
    identifier: identifier,
    vendor: "OpenRouter",
    name: name,
    cost: 5,
    enabled: true,
    context_length: 32_000,
    max_tokens: 512
  }
  |> Repo.insert!()
end)
