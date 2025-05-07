defmodule Chat.Inference do
  import Ecto.Query

  alias Chat.Accounts.{Scope, User}
  alias Chat.Threads.Thread
  alias Chat.Models.Model
  alias Chat.Repo

  def select_model(:title) do
    Repo.get_by!(
      Model,
      id: Application.fetch_env!(:chat, :title_generation_model_id),
      enabled: true
    )
    |> Repo.preload(:model_provider)
  end

  def select_model(:completion) do
    Repo.get_by!(
      Model,
      id: Application.fetch_env!(:chat, :default_model_id),
      enabled: true
    )
    |> Repo.preload(:model_provider)
  end

  def select_model(:completion, %Scope{user: user, thread: nil}) do
    select_model(:completion, user) || select_model(:completion)
  end

  def select_model(:completion, %Scope{thread: thread, user: user}) do
    case select_model(:completion, thread) do
      nil -> select_model(:completion, user) || select_model(:completion)
      model -> model
    end
  end

  def select_model(:completion, %User{} = user) do
    Repo.one(
      from model in Model,
        left_join: user in User,
        on: model.id == user.default_model_id,
        where: user.id == ^user.id and model.enabled == true
    )
    |> Repo.preload(:model_provider)
  end

  def select_model(:completion, %Thread{} = thread) do
    Repo.one(
      from model in Model,
        left_join: thread in Thread,
        on: model.id == thread.model_id,
        where: thread.id == ^thread.id and model.enabled == true
    )
    |> Repo.preload(:model_provider)
  end
end
