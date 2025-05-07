defmodule Chat.Threads.Message do
  use Ecto.Schema
  import Ecto.Changeset

  alias Chat.Threads.Thread
  alias Chat.Models.Model

  schema "messages" do
    field :public_id, :string
    field :status, Ecto.Enum, values: [:processing, :failed, :done], default: :processing
    field :reason, :string, default: ""
    field :role, Ecto.Enum, values: [:system, :context, :user, :assistant]
    field :content_id, :string, default: ""
    field :content, :string, default: ""
    field :token_count, :integer

    timestamps(type: :utc_datetime)

    belongs_to :thread, Thread
    belongs_to :model, Model
    belongs_to :parent, __MODULE__
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [
      :status,
      :reason,
      :role,
      :content_id,
      :content,
      :token_count
    ])
    |> validate_required([:role])
  end
end
