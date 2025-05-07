defmodule Chat.Models.Model do
  use Ecto.Schema
  import Ecto.Changeset

  alias Chat.Models.ModelProvider

  schema "models" do
    field :public_id, :string
    field :identifier, :string
    field :cost, :integer
    field :vendor, :string
    field :name, :string
    field :enabled, :boolean, default: false
    field :context_length, :integer
    field :max_tokens, :integer
    field :temperature, :float
    field :top_p, :float
    field :top_k, :float
    field :frequency_penalty, :float
    field :presence_penalty, :float
    field :repetition_penalty, :float
    field :min_p, :float
    field :top_a, :float

    timestamps(type: :utc_datetime)

    belongs_to :model_provider, ModelProvider
  end

  @doc false
  def changeset(model, attrs, %ModelProvider{} = model_provider) do
    model
    |> cast(attrs, [
      :identifier,
      :cost,
      :vendor,
      :name,
      :enabled,
      :context_length,
      :max_tokens,
      :temperature,
      :top_p,
      :top_k,
      :frequency_penalty,
      :presence_penalty,
      :repetition_penalty,
      :min_p,
      :top_a
    ])
    |> validate_required([
      :identifier,
      :cost,
      :vendor,
      :name,
      :enabled,
      :context_length
    ])
    |> put_change(:model_provider_id, model_provider.id)
  end
end
