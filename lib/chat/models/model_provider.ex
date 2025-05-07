defmodule Chat.Models.ModelProvider do
  use Ecto.Schema
  import Ecto.Changeset

  schema "model_providers" do
    field :name, :string
    field :url, :string
    field :key, :string, default: ""

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(model_provider, attrs) do
    model_provider
    |> cast(attrs, [:name, :url, :key])
    |> validate_required([:name, :url])
    |> validate_length(:name, min: 3, max: 50)
    |> validate_length(:url, min: 10, max: 100)
  end
end
