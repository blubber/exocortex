defmodule Chat.ThreadsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Chat.Threads` context.
  """

  @doc """
  Generate a thread.
  """
  def thread_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        title: "some title"
      })

    {:ok, thread} = Chat.Threads.create_thread(scope, attrs)
    thread
  end

  @doc """
  Generate a prompt.
  """
  def prompt_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{

      })

    {:ok, prompt} = Chat.Threads.create_prompt(scope, attrs)
    prompt
  end
end
