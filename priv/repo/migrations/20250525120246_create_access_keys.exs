defmodule Chat.Repo.Migrations.CreateAccessKeys do
  use Ecto.Migration

  def change do
    create table(:access_keys) do
      add :public_id, :text, null: false
      add :sponsor_id, references(:users, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:access_keys, [:public_id], unique: true)
    create index(:access_keys, [:sponsor_id])
    create index(:access_keys, [:user_id])
  end
end
