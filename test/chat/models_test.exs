defmodule Chat.ModelsTest do
  use Chat.DataCase

  alias Chat.Models

  describe "model_providers" do
    alias Chat.Models.ModelProvider

    import Chat.ModelsFixtures

    @invalid_attrs %{name: nil, key: nil, url: nil}

    test "list_model_providers/0 returns all model_providers" do
      model_provider = model_provider_fixture()
      assert Models.list_model_providers() == [model_provider]
    end

    test "get_model_provider!/1 returns the model_provider with given id" do
      model_provider = model_provider_fixture()
      assert Models.get_model_provider!(model_provider.id) == model_provider
    end

    test "create_model_provider/1 with valid data creates a model_provider" do
      valid_attrs = %{name: "some name", key: "some key", url: "some url"}

      assert {:ok, %ModelProvider{} = model_provider} = Models.create_model_provider(valid_attrs)
      assert model_provider.name == "some name"
      assert model_provider.key == "some key"
      assert model_provider.url == "some url"
    end

    test "create_model_provider/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Models.create_model_provider(@invalid_attrs)
    end

    test "update_model_provider/2 with valid data updates the model_provider" do
      model_provider = model_provider_fixture()
      update_attrs = %{name: "some updated name", key: "some updated key", url: "some updated url"}

      assert {:ok, %ModelProvider{} = model_provider} = Models.update_model_provider(model_provider, update_attrs)
      assert model_provider.name == "some updated name"
      assert model_provider.key == "some updated key"
      assert model_provider.url == "some updated url"
    end

    test "update_model_provider/2 with invalid data returns error changeset" do
      model_provider = model_provider_fixture()
      assert {:error, %Ecto.Changeset{}} = Models.update_model_provider(model_provider, @invalid_attrs)
      assert model_provider == Models.get_model_provider!(model_provider.id)
    end

    test "delete_model_provider/1 deletes the model_provider" do
      model_provider = model_provider_fixture()
      assert {:ok, %ModelProvider{}} = Models.delete_model_provider(model_provider)
      assert_raise Ecto.NoResultsError, fn -> Models.get_model_provider!(model_provider.id) end
    end

    test "change_model_provider/1 returns a model_provider changeset" do
      model_provider = model_provider_fixture()
      assert %Ecto.Changeset{} = Models.change_model_provider(model_provider)
    end
  end

  describe "models" do
    alias Chat.Models.Model

    import Chat.ModelsFixtures

    @invalid_attrs %{name: nil}

    test "list_models/0 returns all models" do
      model = model_fixture()
      assert Models.list_models() == [model]
    end

    test "get_model!/1 returns the model with given id" do
      model = model_fixture()
      assert Models.get_model!(model.id) == model
    end

    test "create_model/1 with valid data creates a model" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Model{} = model} = Models.create_model(valid_attrs)
      assert model.name == "some name"
    end

    test "create_model/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Models.create_model(@invalid_attrs)
    end

    test "update_model/2 with valid data updates the model" do
      model = model_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Model{} = model} = Models.update_model(model, update_attrs)
      assert model.name == "some updated name"
    end

    test "update_model/2 with invalid data returns error changeset" do
      model = model_fixture()
      assert {:error, %Ecto.Changeset{}} = Models.update_model(model, @invalid_attrs)
      assert model == Models.get_model!(model.id)
    end

    test "delete_model/1 deletes the model" do
      model = model_fixture()
      assert {:ok, %Model{}} = Models.delete_model(model)
      assert_raise Ecto.NoResultsError, fn -> Models.get_model!(model.id) end
    end

    test "change_model/1 returns a model changeset" do
      model = model_fixture()
      assert %Ecto.Changeset{} = Models.change_model(model)
    end
  end
end
