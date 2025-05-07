defmodule Chat.Models do
  @moduledoc """
  The Models context.
  """

  import Ecto.Query, warn: false
  alias Chat.Repo

  alias Chat.Accounts.Scope
  alias Chat.Models.{Model, ModelProvider}

  def list_model_providers do
    Repo.all(ModelProvider)
  end

  def get_model_provider!(id), do: Repo.get!(ModelProvider, id)

  def create_model_provider(attrs) do
    %ModelProvider{}
    |> ModelProvider.changeset(attrs)
    |> Repo.insert()
  end

  def update_model_provider(%ModelProvider{} = model_provider, attrs) do
    model_provider
    |> ModelProvider.changeset(attrs)
    |> Repo.update()
  end

  def list_models do
    Repo.all(Model)
  end

  def list_models(%Scope{}) do
    Repo.all(
      from model in Model,
        where: model.enabled == true
    )
  end

  def get_model!(id), do: Repo.get!(Model, id)

  def get_model(public_id) when is_binary(public_id) do
    Repo.one(
      from model in Model,
        where: model.public_id == ^public_id
    )
  end

  def create_model(attrs, %ModelProvider{} = model_provider) do
    %Model{}
    |> Model.changeset(attrs, model_provider)
    |> Chat.PublicId.public_id(:public_id, "m")
    |> Repo.insert()
  end

  def update_model(%Model{} = model, attrs, %ModelProvider{} = model_provider) do
    model
    |> Model.changeset(attrs, model_provider)
    |> Repo.update()
  end
end
