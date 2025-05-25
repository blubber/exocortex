defmodule ChatWeb.ThreadLive do
  use ChatWeb, :live_view

  alias Ecto.Changeset

  alias Chat.Models
  alias Chat.Threads
  alias Chat.Threads.{Thread, Message}
  alias Chat.Models.Model
  alias Chat.Repo
  alias ChatWeb.Suggestions

  def render(assigns) do
    ~H"""
    <div class="
      flex
    flex-col
      h-full
      ">
      <.toolbar aria-label="Toolbar">
        <.button
          aria-label="Search chat history"
          class="block"
          variant="toolbar"
          phx-click={JS.dispatch(":open", to: "#thread-history-dialog")}
          data-kb="Mk"
        >
          <.icon name="hero-chat-bubble-bottom-center-text" class="size-5 md:size-4" />
        </.button>
        <.button
          aria-label="Start a new conversation thread"
          class="block"
          variant="toolbar"
          phx-click={JS.navigate(~p"/thread/new")}
          data-kb="MSo"
        >
          <.icon name="hero-plus" class="size-5 md:size-4" />
        </.button>
        <.button
          variant="toolbar"
          class="flex gap-1 items-center text-sm"
          popovertarget="model-selector"
          id="model-selector-trigger"
        >
          <div>
            {@active_model.name}
          </div>
          <div>
            <.icon name="hero-chevron-down" class="size-4" />
          </div>
        </.button>
      </.toolbar>

      <.alert title="Confirm Delete" id="delete-alert">
        Are you sure you want to delete <strong>Why is the sky blue?</strong>. This
        action is permanent.
        <:action>
          <.button variant="danger">
            Delete
          </.button>
        </:action>
      </.alert>

      <.model_selector {assigns} />

      <div class="flex-1 overflow-y-auto" id="scroll-container">
        <div class="mx-auto max-w-2xl p-2 sm:p-4">
          <.content {assigns} />
        </div>
      </div>

      <div class="p-2 md:p-4 flex justify-center">
        <.form
          for={@form}
          class="flex items-center gap-4 w-full max-w-2xl"
          phx-change="validate"
          phx-submit="submit"
        >
          <div class="flex-1">
            <.input
              type="textarea"
              field={@form[:prompt]}
              autocomplete="off"
              autofocus
              class="w-full field-sizing-content leading-6 md:min-h-15 max-md:max-h-15 md:max-h-123"
              placeholder="Write your message."
              data-kb="/"
              data-kb-action="focus"
              phx-hook="Prompt"
              id="prompt"
            />
          </div>

          <div>
            <button
              type="submit"
              class="text-white/70 hover:text-white cursor-pointer p-1.5 disabled:text-white/50 disabled:cursor-default"
              id="submit-prompt"
            >
              <span class="sr-only">Submit prompt</span>
              <.icon name="hero-paper-airplane-solid" class="size-5 rotate-315" />
            </button>
          </div>
        </.form>
      </div>
    </div>
    <.history_dialog {assigns} />
    """
  end

  defp content(%{thread: nil} = assigns) do
    ~H"""
    <div class="bg-bismuth-900 border border-solid border-bismuth-700 rounded-lg w-full md:max-w-md mt-12 md:mt-24 flex flex-col gap-4 p-2 md:p-4">
      <div class="transition-all starting:opacity-0 opacity-100 duration-250">
        <.title class="text-lg md:text-xl">How can I help you today?</.title>
      </div>
      <div>
        <ul>
          <li
            :for={{{key, prompt}, i} <- Enum.with_index(@suggestions, 1)}
            class="block transition-all starting:opacity-0 opacity-100 duration-300"
            style={"transition-delay: #{i * 150}ms"}
          >
            <button
              type="button"
              class="cursor-pointer text-sm block w-full rounded-md text-start p-3 text-bismuth-300/90 hover:text-bismuth-100 hover:bg-bismuth-800 border border-solid border-transparent hover:border-bismuth-700 transition-all"
              phx-click="suggest"
              phx-value-suggestion={key}
            >
              {prompt}
            </button>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  defp content(assigns) do
    ~H"""
    <main class="flex flex-col gap-8" phx-update="stream" id="thread-container" phx-hook="Thread">
      <div :for={{id, message} <- @streams.messages} id={id}>
        <hr :if={message.role == :user} class="mx-16 mb-8 text-bismuth-700" />
        <.chat_bubble message={message} id={id} />
      </div>
    </main>
    """
  end

  defp chat_bubble(%{message: %Message{role: :user}} = assigns) do
    ~H"""
    <div class="ps-10 flex flex-col items-end">
      <div class="bg-bismuth-600/50 rounded-lg px-3 py-2 border border-bismuth-700">
        <div
          class="markdown"
          phx-hook="Markdown"
          data-role="user"
          data-content-id={@message.content_id}
          id={"#{@id}-user-content"}
          phx-update="ignore"
          phx-no-format
        >{@message.content}
    </div>
      </div>
    </div>
    """
  end

  defp chat_bubble(%{message: %Message{role: :assistant, status: :failed}} = assigns) do
    ~H"""
    <div class="flex flex-col items-start pe-10">
      <div class="px-3 py-2 bg-orange-900 text-orange-200 border border-orange-700 flex gap-4">
        <.icon name="hero-exclamation-triangle" class="block size-5" />
        <div>An error occured, please try again later.</div>
      </div>
    </div>
    """
  end

  defp chat_bubble(%{message: %Message{role: :assistant}} = assigns) do
    ~H"""
    <div class="flex flex-col items-start pe-10">
      <div class="px-3 py-2">
        <div
          class="markdown"
          phx-hook="Markdown"
          data-role="assistant"
          data-content-id={@message.content_id}
          data-message-id={@message.public_id}
          data-status={@message.status}
          phx-update="ignore"
          id={"#{@id}-assistant-content"}
          phx-no-format
        >{@message.content}</div>
      </div>
    </div>
    """
  end

  defp model_selector(assigns) do
    ~H"""
    <div
      popover
      id="model-selector"
      class="bg-bismuth-900 border border-solid border-bismuth-700 p-2 sm:p-4 rounded-lg open:flex flex-col gap-4 text-zinc-300 overflow-none"
    >
      <header class="flex flex-col gap-2">
        <div>
          <.title class="text-sm sm:text-base">Models</.title>
        </div>
        <div>
          <.input
            type="search"
            name="search-mdoels"
            id="model-selector-search"
            autocomplete="off"
            autofocus
            value=""
            placeholder="Filter models"
          />
        </div>
      </header>

      <div>
        <ul
          class="block"
          phx-hook="List"
          id="model-selector-list"
          data-search="#model-selector-search"
          data-delegate="#model-selector"
          phx-update="stream"
        >
          <li :for={{id, model} <- @streams.models} id={id} data-list-item={model.name} class="my-2">
            <button
              type="button"
              class="block w-full cursor-pointer p-2 text-left border border-solid border-transparent hover:hover-bismuth-600 hover:bg-bismuith-600"
              phx-click="select-model"
              phx-value-model={model.public_id}
            >
              {model.name}
            </button>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  defp history_dialog(assigns) do
    ~H"""
    <.dialog title="Chat History" id="thread-history-dialog" aria-live="polite">
      <:header>
        <.input
          type="search"
          value=""
          name="search-thread"
          autofocus
          autocomplete="off"
          id="thread-history-search"
          placeholder="Search chat history"
        />
      </:header>

      <ul
        id="thread-history-list"
        phx-hook="List"
        data-search="#thread-history-search"
        data-delegate="#thread-history-dialog"
      >
        <li
          :for={{id, thread} <- @streams.threads}
          id={id}
          data-list-item={if(thread.title == "", do: "New Chat", else: thread.title)}
        >
          <.button
            navigate={"/thread/#{thread.public_id}"}
            variant="blank"
            class="block w-full rounded-md text-start p-2 text-bismuth-300/90 hover:text-bismuth-100 hover:bg-bismuth-800 border border-solid border-transparent hover:border-bismuth-700 transition-all my-1"
          >
            {if(thread.title == "", do: "New Chat", else: thread.title)}
          </.button>
        </li>
      </ul>
    </.dialog>
    """
  end

  def handle_event("validate", %{"prompt" => params}, socket) do
    changeset = changeset(params)
    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("submit", %{"prompt" => params}, socket) do
    case changeset(params) do
      %Changeset{valid?: true} = changeset ->
        user_content = Ecto.Changeset.get_change(changeset, :prompt)

        {:noreply,
         socket
         |> assign_form(changeset(%{}))
         |> prompt(user_content)}

      %Changeset{valid?: false} = changeset ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("suggest", %{"suggestion" => suggestion}, socket) do
    messages =
      Suggestions.messages(suggestion)

    scope = socket.assigns.current_scope

    model = Chat.Inference.select_model(:completion, scope)

    {:ok, thread} = Threads.create_thread(scope, model, %{title: "New Chat"})
    scope = Map.put(scope, :thread, thread)

    user_message =
      Enum.reduce(messages, nil, fn attrs, _ ->
        {:ok, user_message} = Threads.create_message(scope, model, attrs)
        user_message
      end)

    ChatWeb.ThreadServer.chat_completion(scope, user_message, model)

    {:noreply,
     socket
     |> push_navigate(to: ~p"/thread/#{thread.public_id}")}
  end

  def handle_event("select-model", %{"model" => public_id}, socket) do
    %{current_scope: scope} = socket.assigns

    with %Model{} = model <- Chat.Models.get_model(public_id),
         user <- Chat.Accounts.set_default_model(scope.user, model),
         thread <- set_thread_model(socket.assigns.thread, scope, model) do
      {:noreply,
       socket
       |> assign(thread: thread, active_model: model, current_scope: Map.put(scope, :user, user))}
    else
      _ ->
        {:noreply, socket}
    end
  end

  def set_thread_model(nil, _, _), do: nil

  def set_thread_model(%Thread{} = thread, scope, model) do
    {:ok, thread} = Threads.update_thread(scope, model, thread, %{})
    thread
  end

  defp prompt(%{assigns: %{thread: nil}} = socket, prompt) do
    scope = socket.assigns.current_scope

    model = Chat.Inference.select_model(:completion, scope)

    {:ok, thread} = Threads.create_thread(scope, model, %{title: "New Chat"})

    socket
    |> assign(thread: thread, current_scope: Map.put(scope, :thread, thread))
    |> push_navigate(to: ~p"/thread/#{thread.public_id}")
    |> prompt(prompt)
  end

  defp prompt(%{assigns: %{thread: %Thread{}}} = socket, prompt) do
    scope = socket.assigns.current_scope

    model = Chat.Inference.select_model(:completion, scope)

    {:ok, user_message} =
      Threads.create_message(scope, model, %{role: :user, content: prompt, status: :done})

    ChatWeb.ThreadServer.chat_completion(scope, user_message, model)

    socket
  end

  def mount(_params, _session, socket) do
    %{current_scope: scope} = socket.assigns

    ChatWeb.ThreadSupervisor.ensure_thread_server_started(scope.user)

    Threads.subscribe_threads(scope)

    models = Models.list_models(scope)
    threads = Threads.list_threads(scope)

    {:ok,
     socket
     |> assign_form(changeset(%{}))
     |> stream_configure(:models, dom_id: & &1.public_id)
     |> stream(:models, models)
     |> stream_configure(:threads, dom_id: & &1.public_id)
     |> stream(:threads, threads)
     |> stream_configure(:messages, dom_id: & &1.public_id)}
  end

  def handle_params(%{"public_id" => public_id}, _uri, socket) do
    %{current_scope: scope} = socket.assigns

    thread = Threads.get_thread!(scope, public_id)

    scope = Map.put(scope, :thread, thread)
    ChatWeb.ThreadServer.prepare_thread(scope)

    active_model = Chat.Inference.select_model(:completion, scope)

    messages =
      scope
      |> Threads.query_messages()
      |> Threads.filter_visible()
      |> Threads.list_messages()
      |> Repo.preload(:model)

    socket =
      case ChatWeb.ThreadServer.chunks(scope) do
        nil ->
          socket

        {assistant_message, chunks} ->
          event_data = %{
            message_id: assistant_message.public_id,
            chunks:
              Enum.map(chunks, fn {chunk, index} ->
                %{index: index, delta: chunk.content}
              end)
          }

          push_event(socket, "update-completion:#{assistant_message.public_id}", event_data)
      end

    {:noreply,
     socket
     |> assign(
       thread: thread,
       current_scope: scope,
       active_model: active_model
     )
     |> stream(:messages, messages)}
  end

  def handle_params(_params, _uri, socket) do
    active_model = Chat.Inference.select_model(:completion, socket.assigns.current_scope)

    {:noreply,
     assign(socket,
       thread: nil,
       suggestions: Suggestions.suggestions(),
       active_model: active_model
     )}
  end

  def handle_info({:created, %Thread{} = thread}, socket) do
    {:noreply, stream_insert(socket, :threads, thread)}
  end

  def handle_info({:updated, %Thread{} = thread}, socket) do
    {:noreply, stream_insert(socket, :threads, thread)}
  end

  def handle_info(
        {:created, %Message{} = message},
        %{assigns: %{thread: %Thread{} = thread}} = socket
      )
      when thread.id == message.thread_id do
    {:noreply, stream_insert(socket, :messages, message)}
  end

  def handle_info(
        {:updated, %Message{} = message},
        %{assigns: %{thread: %Thread{} = thread}} = socket
      )
      when thread.id == message.thread_id do
    event_data = %{
      status: message.status,
      content: message.content,
      content_id: message.content_id
    }

    {:noreply,
     socket
     |> stream_insert(:messages, message)
     |> push_event("updated-message:#{message.public_id}", event_data)}
  end

  def handle_info(
        {:update_completion, %Message{} = message, {chunk, index}},
        %{assigns: %{thread: %Thread{} = thread}} = socket
      )
      when thread.id == message.thread_id do
    event_data = %{
      message_id: message.public_id,
      chunks: [%{index: index, delta: chunk.content}]
    }

    {:noreply, push_event(socket, "update-completion:#{message.public_id}", event_data)}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  defp assign_form(socket, changeset) do
    assign(socket, changeset: changeset, form: to_form(changeset, as: "prompt"))
  end

  defp changeset(attrs) do
    {%{}, %{prompt: :string}}
    |> Changeset.cast(attrs, [:prompt])
    |> Changeset.validate_required(:prompt)
    |> Changeset.validate_length(:prompt, min: 2, max: 10_000)
  end
end
