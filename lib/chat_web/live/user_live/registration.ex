defmodule ChatWeb.UserLive.Registration do
  use ChatWeb, :live_view

  alias Chat.Accounts
  alias Chat.Accounts.User

  def render(assigns) do
    ~H"""
    <Layouts.focus current_scope={@current_scope} class="flex flex-col gap-8 md:gap-12">
      <.header class="text-center">
        Register
        <:subtitle>
          Register for a free account to get started. Already have an account, <.link
            class="font-semibold"
            navigate={~p"/users/log-in"}
          >Log in</.link>.
        </:subtitle>
      </.header>

      <div class="borderborder-bismuth-700 flex flex-col gap-4 rounded-lg bg-bismuth-900 p-2 sm:p-4">
        <.form for={@form} phx-change="validate" phx-submit="save" class="contents">
          <div class="flex flex-col gap-1">
            <.label for={@form[:email].id}>Email address</.label>
            <.input field={@form[:email]} type="email" required />
          </div>

          <div class="flex flex-col gap-1">
            <.label for={@form[:name].id} required={false}>Name</.label>
            <.input field={@form[:name]} type="text" />
          </div>

          <div class="flex flex-col gap-1">
            <.label for={@form[:password].id} required={false}>Password *</.label>
            <.input field={@form[:password]} type="password" />
          </div>

          <div class="flex flex-col gap-1">
            <.label for={@form[:access_key].id}>Key</.label>
            <.input field={@form[:access_key]} type="text" required />
          </div>

          <div class="flex justify-end mt-8">
            <.button variant="primary" type="submit" disabled={!@changeset.valid?}>
              Sign up
            </.button>
          </div>

          <div class="text-sm text-zinc-400 mt-8">
            *: If you don't set a password you can log in using your email address.
          </div>
        </.form>
      </div>

      <div class="text-sm text-center text-zinc-400">
        By signing up you agree to you <.link href="">privay policy</.link>
        and <.link href="">terms of service</.link>.
      </div>
    </Layouts.focus>
    """
  end

  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: ChatWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = User.registration_changeset(%User{}, %{})

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil, user: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

        {:noreply, assign(socket, user: user)}

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset)
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      User.registration_changeset(%User{}, user_params)
      |> IO.inspect()

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form, changeset: changeset)
  end
end
