defmodule ChatWeb.UserLive.Registration do
  use ChatWeb, :live_view

  alias Chat.Accounts
  alias Chat.Accounts.User

  def render(assigns) do
    ~H"""
    <Layouts.focus current_scope={@current_scope}>
      <div class={[
        "starting:opacity-0 transition-all transition-discrete duration-200",
        if(@user != nil, do: "hidden opacity-0", else: "opacity-100")
      ]}>
        <.header class="text-center">
          Register for an account
          <:subtitle>
            Already registered?
            <.link navigate={~p"/users/log-in"} class="font-semibold">
              Log in
            </.link>
            to your account now.
          </:subtitle>
        </.header>

        <.form
          for={@form}
          id="registration_form"
          phx-submit="save"
          phx-change="validate"
          class="flex flex-col gap-6"
        >
          <.fieldset field={@form[:email]} label="Email">
            <.input
              field={@form[:email]}
              type="email"
              autocomplete="username"
              required
              phx-mounted={JS.focus()}
            />
          </.fieldset>

          <.button variant="primary" phx-disable-with="Creating account..." class="w-full">
            Create an account
          </.button>
        </.form>
      </div>
      <div
        :if={@user != nil}
        current_scope={@current_scope}
        class={[
          "starting:opacity-0 transition-all transition-discrete duration-200 delay-200",
          if(@user == nil, do: "hidden opacity-0", else: "opacity-100")
        ]}
      >
        <.header>
          Welcome!
          <:subtitle>
            We sent a confirmation email to <strong class="font-semibold">{@user.email}</strong>.
            Please check your inbox and click the link in the email to confirm your account.
          </:subtitle>
        </.header>
      </div>
    </Layouts.focus>
    """
  end

  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: ChatWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_email(%User{})

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
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_email(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
