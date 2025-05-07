defmodule Chat.Accounts.Scope do
  alias Chat.Accounts.User

  defstruct user: nil, thread: nil

  def for_user(%User{} = user) do
    %__MODULE__{user: user}
  end

  def for_user(nil), do: nil
end
