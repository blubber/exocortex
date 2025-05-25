defmodule Chat.Accounts.AccessKey do
  use Ecto.Schema
  import Ecto.Changeset

  alias Chat.Accounts.User
  alias Chat.Accounts.User

  schema "access_keys" do
    field :public_id, :string

    timestamps(type: :utc_datetime)

    belongs_to :sponsor, User, foreign_key: :sponsor_id
    belongs_to :user, User, foreign_key: :user_id
  end

  def changeset(%User{} = sponsor) do
    %__MODULE__{}
    |> change()
    |> Chat.PublicId.public_id(:public_id, "ak", 16)
    |> put_change(:sponsor_id, sponsor.id)
  end

  def changeset(access_key, %User{} = user) do
    access_key
    |> change()
    |> put_change(:user_id, user.id)
  end
end
