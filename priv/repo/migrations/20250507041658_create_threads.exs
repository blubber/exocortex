defmodule Chat.Repo.Migrations.CreateThreads do
  use Ecto.Migration

  def change do
    create table(:threads) do
      add :public_id, :text, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :model_id, references(:models, on_delete: :restrict), null: false

      add :last_active_at, :utc_datetime
      add :archived_at, :utc_datetime
      add :title, :text, null: false
      add :user_title, :text, null: false, default: ""

      timestamps(type: :utc_datetime)
    end

    create index(:threads, [:public_id], unique: true)
    create index(:threads, [:user_id])
    create index(:threads, [:model_id])

    create table(:messages) do
      add :public_id, :text, null: false
      add :thread_id, references(:threads, on_delete: :delete_all), null: false
      add :model_id, references(:models, on_delete: :restrict)
      add :parent_id, references(:messages, on_delete: :restrict)

      add :role, :text, null: false
      add :status, :text, null: false
      add :reason, :text, null: false
      add :content_id, :text, null: false, default: ""
      add :content, :text, null: false, default: ""
      add :token_count, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:public_id], unique: true)
    create index(:messages, [:thread_id])
    create index(:messages, [:model_id])

    alter table(:users) do
      add :default_model_id, references(:models, on_delete: :nilify_all), null: true
    end
  end
end
