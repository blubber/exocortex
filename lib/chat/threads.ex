defmodule Chat.Threads do
  @moduledoc """
  The Threads context.
  """

  import Ecto.Query, warn: false
  alias Chat.Repo

  alias Chat.Threads.{Message, Thread}
  alias Chat.Models.Model
  alias Chat.Accounts.Scope

  def subscribe_threads(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Chat.PubSub, "user:#{key}:threads")
  end

  def broadcast(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Chat.PubSub, "user:#{key}:threads", message)
  end

  def list_threads(%Scope{} = scope) do
    Repo.all(from thread in Thread, where: thread.user_id == ^scope.user.id)
  end

  def get_thread!(%Scope{} = scope, id) when is_integer(id) do
    Repo.get_by!(Thread, id: id, user_id: scope.user.id)
  end

  def get_thread!(%Scope{} = scope, id) when is_binary(id) do
    Repo.one!(
      from thread in Thread,
        where: thread.public_id == ^id and thread.user_id == ^scope.user.id
    )
  end

  def reset_thread(%Scope{} = scope, %Thread{} = thread) do
    true = thread.user_id == scope.user.id

    Repo.update_all(
      from(message in Message,
        where:
          message.thread_id == ^thread.id and message.role == :assistant and
            message.status == :processing
      ),
      set: [status: :failed, reason: "timeout"]
    )
  end

  def create_thread(%Scope{} = scope, %Model{} = model, attrs) do
    with {:ok, thread = %Thread{}} <-
           %Thread{}
           |> Thread.changeset(attrs, scope, model)
           |> Chat.PublicId.public_id(:public_id, "t")
           |> Repo.insert() do
      broadcast(scope, {:created, thread})
      {:ok, thread}
    end
  end

  def update_thread(%Scope{} = scope, %Model{} = model, %Thread{} = thread, attrs) do
    true = thread.user_id == scope.user.id

    with {:ok, thread = %Thread{}} <-
           thread
           |> Thread.changeset(attrs, scope, model)
           |> Repo.update() do
      broadcast(scope, {:updated, thread})
      {:ok, thread}
    end
  end

  def delete_thread(%Scope{} = scope, %Thread{} = thread) do
    true = thread.user_id == scope.user.id

    with {:ok, thread = %Thread{}} <-
           Repo.delete(thread) do
      broadcast(scope, {:deleted, thread})
      {:ok, thread}
    end
  end

  def change_thread(%Scope{} = scope, %Model{} = model, %Thread{} = thread, attrs \\ %{}) do
    true = thread.user_id == scope.user.id

    Thread.changeset(thread, attrs, scope, model)
  end

  def query_messages(%Scope{thread: %Thread{} = thread}) do
    from m in Message,
      where: m.thread_id == ^thread.id,
      left_join: p in Message,
      on: m.parent_id == p.id,
      order_by: [
        asc: fragment("COALESCE(?, ?)", p.inserted_at, m.inserted_at),
        asc: fragment("COALESCE(?, 0)", m.parent_id),
        asc: m.id
      ]
  end

  def filter_visible(%Ecto.Query{} = query) do
    where(query, [m], m.role == :user or m.role == :assistant)
  end

  def filter_context(%Ecto.Query{} = query) do
    where(query, [m], m.status == :done)
  end

  def list_messages(%Ecto.Query{} = query) do
    Repo.all(query)
  end

  def create_message(
        %Scope{user: user, thread: %Thread{} = thread} = scope,
        %Model{} = model,
        attrs
      ) do
    true = user.id == thread.user_id

    with {:ok, message = %Message{}} <-
           %Message{}
           |> Message.changeset(attrs)
           |> Ecto.Changeset.put_change(:thread_id, thread.id)
           |> Ecto.Changeset.put_change(:model_id, model.id)
           |> Chat.PublicId.public_id(:public_id, "m")
           |> Repo.insert() do
      broadcast(scope, {:created, message})
      {:ok, message}
    end
  end

  def update_message(%Scope{thread: %Thread{} = thread} = scope, message, attrs) do
    true = thread.id == message.thread_id

    with {:ok, message = %Message{}} <-
           message
           |> Message.changeset(attrs)
           |> Repo.update() do
      broadcast(scope, {:updated, message})
      {:ok, message}
    end
  end
end
