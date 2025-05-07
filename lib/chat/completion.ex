defmodule Chat.Completion.Chunk do
  defstruct [:content, :finished, :input_tokens, :output_tokens]
end

defmodule Chat.Completion do
  alias Chat.Models.{Model, ModelProvider}
  alias Chat.Completion.Chunk

  def prepare_request(%Model{model_provider: %ModelProvider{} = model_provider}) do
    {
      model_provider.url <> "/chat/completions",
      [
        {"content-type", "application/json"},
        {"Authorization", "Bearer #{model_provider.key}"}
      ]
    }
  end

  def prepare_body(%Model{model_provider: %ModelProvider{}} = model, messages) do
    %{
      stream: true,
      model: model.identifier,
      messages:
        messages
        |> Enum.filter(&(&1.status == :done))
        |> Enum.map(
          &%{
            role:
              case &1.role do
                :system -> "system"
                _ -> "user"
              end,
            content: &1.content
          }
        )
    }
  end

  def parse_chunk(chunk) do
    chunk
    |> String.split(~r/\r?\n/)
    |> Enum.map(&String.trim/1)
    |> Enum.map(fn line ->
      case Regex.run(~r/data: (\{.+\})/, line, capture: :all_but_first) do
        [data] -> data
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&Jason.decode/1)
    |> Enum.map(&into_chunk/1)
    |> Enum.reject(&is_nil/1)
  end

  def into_chunk({:ok, %{"choices" => [choice | _]} = data}) do
    usage = Map.get(data, "usage", %{})

    %Chunk{
      content: choice["delta"]["content"],
      finished: true,
      input_tokens: Map.get(usage, "prompt_tokens", 0),
      output_tokens: Map.get(usage, "completion_tokens", 0)
    }
  end

  def into_chunk(_), do: nil
end
