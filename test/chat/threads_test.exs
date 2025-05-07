defmodule Chat.ThreadsTest do
  use Chat.DataCase

  alias Chat.Threads

  describe "threads" do
    alias Chat.Threads.Thread

    import Chat.AccountsFixtures, only: [user_scope_fixture: 0]
    import Chat.ThreadsFixtures

    @invalid_attrs %{title: nil}

    test "list_threads/1 returns all scoped threads" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      thread = thread_fixture(scope)
      other_thread = thread_fixture(other_scope)
      assert Threads.list_threads(scope) == [thread]
      assert Threads.list_threads(other_scope) == [other_thread]
    end

    test "get_thread!/2 returns the thread with given id" do
      scope = user_scope_fixture()
      thread = thread_fixture(scope)
      other_scope = user_scope_fixture()
      assert Threads.get_thread!(scope, thread.id) == thread
      assert_raise Ecto.NoResultsError, fn -> Threads.get_thread!(other_scope, thread.id) end
    end

    test "create_thread/2 with valid data creates a thread" do
      valid_attrs = %{title: "some title"}
      scope = user_scope_fixture()

      assert {:ok, %Thread{} = thread} = Threads.create_thread(scope, valid_attrs)
      assert thread.title == "some title"
      assert thread.user_id == scope.user.id
    end

    test "create_thread/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Threads.create_thread(scope, @invalid_attrs)
    end

    test "update_thread/3 with valid data updates the thread" do
      scope = user_scope_fixture()
      thread = thread_fixture(scope)
      update_attrs = %{title: "some updated title"}

      assert {:ok, %Thread{} = thread} = Threads.update_thread(scope, thread, update_attrs)
      assert thread.title == "some updated title"
    end

    test "update_thread/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      thread = thread_fixture(scope)

      assert_raise MatchError, fn ->
        Threads.update_thread(other_scope, thread, %{})
      end
    end

    test "update_thread/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      thread = thread_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Threads.update_thread(scope, thread, @invalid_attrs)
      assert thread == Threads.get_thread!(scope, thread.id)
    end

    test "delete_thread/2 deletes the thread" do
      scope = user_scope_fixture()
      thread = thread_fixture(scope)
      assert {:ok, %Thread{}} = Threads.delete_thread(scope, thread)
      assert_raise Ecto.NoResultsError, fn -> Threads.get_thread!(scope, thread.id) end
    end

    test "delete_thread/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      thread = thread_fixture(scope)
      assert_raise MatchError, fn -> Threads.delete_thread(other_scope, thread) end
    end

    test "change_thread/2 returns a thread changeset" do
      scope = user_scope_fixture()
      thread = thread_fixture(scope)
      assert %Ecto.Changeset{} = Threads.change_thread(scope, thread)
    end
  end

  describe "prompts" do
    alias Chat.Threads.Prompt

    import Chat.AccountsFixtures, only: [user_scope_fixture: 0]
    import Chat.ThreadsFixtures

    @invalid_attrs %{}

    test "list_prompts/1 returns all scoped prompts" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      prompt = prompt_fixture(scope)
      other_prompt = prompt_fixture(other_scope)
      assert Threads.list_prompts(scope) == [prompt]
      assert Threads.list_prompts(other_scope) == [other_prompt]
    end

    test "get_prompt!/2 returns the prompt with given id" do
      scope = user_scope_fixture()
      prompt = prompt_fixture(scope)
      other_scope = user_scope_fixture()
      assert Threads.get_prompt!(scope, prompt.id) == prompt
      assert_raise Ecto.NoResultsError, fn -> Threads.get_prompt!(other_scope, prompt.id) end
    end

    test "create_prompt/2 with valid data creates a prompt" do
      valid_attrs = %{}
      scope = user_scope_fixture()

      assert {:ok, %Prompt{} = prompt} = Threads.create_prompt(scope, valid_attrs)
      assert prompt.user_id == scope.user.id
    end

    test "create_prompt/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Threads.create_prompt(scope, @invalid_attrs)
    end

    test "update_prompt/3 with valid data updates the prompt" do
      scope = user_scope_fixture()
      prompt = prompt_fixture(scope)
      update_attrs = %{}

      assert {:ok, %Prompt{} = prompt} = Threads.update_prompt(scope, prompt, update_attrs)
    end

    test "update_prompt/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      prompt = prompt_fixture(scope)

      assert_raise MatchError, fn ->
        Threads.update_prompt(other_scope, prompt, %{})
      end
    end

    test "update_prompt/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      prompt = prompt_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Threads.update_prompt(scope, prompt, @invalid_attrs)
      assert prompt == Threads.get_prompt!(scope, prompt.id)
    end

    test "delete_prompt/2 deletes the prompt" do
      scope = user_scope_fixture()
      prompt = prompt_fixture(scope)
      assert {:ok, %Prompt{}} = Threads.delete_prompt(scope, prompt)
      assert_raise Ecto.NoResultsError, fn -> Threads.get_prompt!(scope, prompt.id) end
    end

    test "delete_prompt/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      prompt = prompt_fixture(scope)
      assert_raise MatchError, fn -> Threads.delete_prompt(other_scope, prompt) end
    end

    test "change_prompt/2 returns a prompt changeset" do
      scope = user_scope_fixture()
      prompt = prompt_fixture(scope)
      assert %Ecto.Changeset{} = Threads.change_prompt(scope, prompt)
    end
  end
end
