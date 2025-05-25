defmodule Chat.Repo.Migrations.AddName do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :name, :text, null: false, default: ""
    end
  end
end
