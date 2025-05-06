defmodule ChatWeb.UserLive.Login do
  use ChatWeb, :live_view

  alias Chat.Accounts

  def render(assigns) do
    ~H"""
    <Layouts.focus current_scope={@current_scope}>
      <div class={[
        "starting:opacity-0 transition-all transition-discrete duration-200",
        if(@email != nil, do: "hidden opacity-0", else: "opacity-100")
      ]}>
        <.header class="text-center">
          Log in
          <:subtitle>
            <%= if @current_scope do %>
              You need to reauthenticate to perform sensitive actions on your account.
            <% else %>
              Don't have an account? <.link
                navigate={~p"/users/register"}
                class="font-semibold"
                phx-no-format
              >Sign up</.link> for an account now.
            <% end %>
          </:subtitle>
        </.header>

        <.form
          :let={f}
          for={@form}
          id="login_form_magic"
          action={~p"/users/log-in"}
          phx-submit="submit_magic"
          class="flex flex-col gap-6"
        >
          <.fieldset field={f[:email]} label="Email">
            <.input
              readonly={!!@current_scope}
              field={f[:email]}
              type="email"
              autocomplete="username"
              required
              phx-mounted={JS.focus()}
            />
          </.fieldset>

          <.button class="w-full" variant="primary">
            Log in with email <span aria-hidden="true">→</span>
          </.button>
        </.form>
      </div>
      <div class={[
        "starting:opacity-0 transition-all transition-discrete duration-200 delay-200",
        if(@email == nil, do: "hidden opacity-0", else: "opacity-100")
      ]}>
        <.header>
          Check your inbox
          <:subtitle>
            An email was sent to <strong class="font-semibold">{@email}</strong> with a
            login link. If you don't receive the email please try again.
          </:subtitle>
          <:actions>
            <.button navigate={~p"/users/log-in"} variant="primary">
              Try again
            </.button>
          </:actions>
        </.header>
      </div>
    </Layouts.focus>
    """
  end

  def mount(_params, _session, socket) do
    form = to_form(%{"email" => ""}, as: "user")
    {:ok, assign(socket, form: form, email: nil)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    {:noreply, assign(socket, email: email)}
  end
end
