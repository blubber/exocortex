defmodule ChatWeb.UserLive.Login do
  use ChatWeb, :live_view

  alias Chat.Accounts

  def render(assigns) do
    ~H"""
    <Layouts.focus current_scope={@current_scope} class="flex flex-col gap-8 md:gap-12">
      <.header class="text-center">
        Log in
        <:subtitle>
          Log in using your email and password, or just your email. Don't have an
          account yet? <.link navigate={~p"/users/register"} class="font-semibold">Sign up for free</.link>.
        </:subtitle>
      </.header>

      <div class="borderborder-bismuth-700 flex flex-col gap-4 rounded-lg bg-bismuth-900 p-2 sm:p-4">
        <div :if={@state == :error} class="flex gap-6 mb-8">
          <div>
            <.icon name="hero-exclamation-circle" class="size-6 text-red-400" />
          </div>
          <div>
            <.title class="text-lg text-red-400">Unable to log in</.title>
            <p class="text-sm text-zinc-400">
              The email address and/or password where incorrect, please tryr again. If you
              forgot your password you can sign in with just your email by leaving the password field
              blank.
            </p>
          </div>
        </div>

        <.form
          for={@form}
          phx-submit="submit"
          class="contents"
          phx-trigger-action={@trigger_submit}
          action={~p"/users/log-in"}
        >
          <div class="flex flex-col gap-1">
            <.label for={@form[:email].id}>Email address</.label>
            <.input field={@form[:email]} type="email" required />
          </div>

          <div class="flex flex-col gap-1">
            <.label for={@form[:password].id} required={false}>Password</.label>
            <.input field={@form[:password]} type="password" />
            <div class="text-sm text-zinc-400 px-2">
              Leave blank to log in using email only.
            </div>
          </div>

          <div class="flex justify-end mt-8">
            <.button variant="primary" type="submit" disabled={@state == :confirm}>
              Log in
            </.button>
          </div>
        </.form>
      </div>
    </Layouts.focus>
    """
  end

  def mount(_params, _session, socket) do
    email = socket.assigns[:flash]["email"]

    form =
      to_form(
        %{"email" => email || "", "password" => ""},
        as: "user"
      )

    {:ok, assign(socket, state: email && :error, form: form, trigger_submit: false)}
  end

  def handle_event(
        "submit",
        %{"user" => %{"email" => email, "password" => ""} = params},
        socket
      ) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    form = to_form(params, as: "user")

    {:noreply, assign(socket, confirm: user && :confirm, form: form)}
  end

  def handle_event("submit", _params, socket) do
    {:noreply, assign(socket, state: :confirm, trigger_submit: true)}
  end
end
