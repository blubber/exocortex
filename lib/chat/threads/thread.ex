defmodule Chat.Threads.Thread do
  use Ecto.Schema
  import Ecto.Changeset

  alias Chat.Models.Model
  alias Chat.Accounts.User

  schema "threads" do
    field :public_id, :string
    field :last_active_at, :utc_datetime
    field :archived_at, :utc_datetime
    field :title, :string
    field :user_title, :string, default: ""

    timestamps(type: :utc_datetime)

    belongs_to :user, User
    belongs_to :model, Model
  end

  @doc false
  def changeset(thread, attrs, user_scope, %Model{} = model) do
    thread
    |> cast(attrs, [:title, :user_title, :last_active_at, :archived_at])
    |> put_change(:user_id, user_scope.user.id)
    |> put_change(:model_id, model.id)
    |> validate_required([:title])
    |> validate_length(:title, min: 3, max: 50)
    |> validate_length(:user_title, max: 50)
  end
end
