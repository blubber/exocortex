defmodule Chat.PublicId do
  def generate(prefix, num_bytes \\ 8) do
    :crypto.strong_rand_bytes(num_bytes)
    |> Base.url_encode64(padding: false)
    |> then(&"#{prefix}#{&1}")
  end

  def public_id(%Ecto.Changeset{} = changeset, field, prefix, num_bytes \\ 8) do
    changeset
    |> Ecto.Changeset.put_change(field, generate(prefix, num_bytes))
  end
end
