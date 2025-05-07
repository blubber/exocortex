defmodule Chat.Repo.Migrations.CreateModelProviders do
  use Ecto.Migration

  def change do
    create table(:model_providers) do
      add :name, :text, null: false
      add :url, :text, null: false
      add :key, :text, null: false, default: ""

      timestamps(type: :utc_datetime)
    end

    create table(:models) do
      add :public_id, :text, null: false

      add :model_provider_id,
          references(:model_providers, on_delete: :delete_all),
          null: false

      add :identifier, :text, null: false
      add :cost, :integer, null: false
      add :vendor, :text, null: false
      add :name, :text, null: false
      add :enabled, :boolean, default: false, null: false
      add :context_length, :integer, null: false
      add :max_tokens, :integer
      add :temperature, :float
      add :top_p, :float
      add :top_k, :float
      add :frequency_penalty, :float
      add :presence_penalty, :float
      add :repetition_penalty, :float
      add :min_p, :float
      add :top_a, :float

      timestamps(type: :utc_datetime)
    end

    create index(:models, [:public_id], unique: true)
    create index(:models, [:model_provider_id])
  end
end
