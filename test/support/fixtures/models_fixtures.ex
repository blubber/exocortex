defmodule Chat.ModelsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Chat.Models` context.
  """

  @doc """
  Generate a model_provider.
  """
  def model_provider_fixture(attrs \\ %{}) do
    {:ok, model_provider} =
      attrs
      |> Enum.into(%{
        key: "some key",
        name: "some name",
        url: "some url"
      })
      |> Chat.Models.create_model_provider()

    model_provider
  end

  @doc """
  Generate a model.
  """
  def model_fixture(attrs \\ %{}) do
    {:ok, model} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Chat.Models.create_model()

    model
  end
end
