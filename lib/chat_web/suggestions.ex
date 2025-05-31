defmodule ChatWeb.Suggestions do
  @suggestions [
    "Why is the sky blue?",
    "Are black holes real?",
    "What is the universe?",
    "How do airplanes fly?",
    "How did life on Earth start",
    "Are we alone in the universe?",
    "What makes us human?",
    "How do plants grow?",
    "What is the animal kingdom?",
    "What is climate change?",
    "How do volcanoes erupt?",
    "What causes weather patterns?",
    "What are stars made of?",
    "What is a galaxy?",
    "What is a tensor?"
  ]

  def suggestions(), do: suggestions(6)

  def suggestions(num), do: Enum.take_random(@suggestions, num)
end
