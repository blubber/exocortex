defmodule ChatWeb.ThreadLive do
  use ChatWeb, :live_view

  import Ecto.Query

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
      <.content {assigns} />

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
    <.toolbar aria-label="Toolbar" class="max-w-[90dvw]">
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
        class="flex gap-1 items-center text-sm min-w-0"
        popovertarget="model-selector"
        id="model-selector-trigger"
      >
        <div class="overflow-hidden text-ellipsis whitespace-nowrap min-w-0 grow-1 shrink-1 basis-0 text-sm">
          {@active_model.name}
        </div>
        <div>
          <.icon name="hero-chevron-down" class="size-4" />
        </div>
      </.button>
    </.toolbar>
    <.model_selector {assigns} />
    <.history_dialog {assigns} />
    """
  end

  defp content(%{thread: nil} = assigns) do
    ~H"""
    <div class="flex-1 flex justify-center items-center">
      <div class="w-full max-w-md">
        <div class="flex flex-col gap-8">
          <div>
            <.title class="text-lg md:text-xl">How can I help you today?</.title>
          </div>
          <div>
            <ul>
              <li
                :for={{prompt, i} <- Enum.with_index(Suggestions.suggestions())}
                class="starting:opacity-0 duration-500"
                style={"transition-delay: #{i * 100}ms"}
              >
                <.button
                  type="button"
                  variant="toolbar"
                  class="text-left w-full block cursor-pointer"
                  phx-click="suggest"
                  phx-value-suggestion={prompt}
                >
                  {prompt}
                </.button>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp content(assigns) do
    ~H"""
    <div
      class="flex-1 overflow-y-auto"
      id="scroll-container"
      phx-hook="Thread"
      data-message-count={@message_count}
    >
      <div class="mx-auto max-w-2xl p-2 sm:p-4">
        <main class="flex flex-col gap-8" phx-update="stream" id="message-container">
          <div :for={{id, message} <- @streams.messages} id={id}>
            <div :if={message.role == :user} class="flex items-center mb-8">
              <div class="flex-1 h-px bg-divider"></div>
            </div>
            <.chat_bubble
              message={message}
              id={"#{id}-container"}
              message_cache_key={@message_cache_key}
            />
          </div>
        </main>
        <div id="scroll-bottom" class="w-full"></div>
      </div>
    </div>
    """
  end

  defp chat_bubble(%{message: %Message{role: :user}} = assigns) do
    ~H"""
    <div class="ps-10 flex flex-col items-end">
      <div class="bg-chat-bubble border-chat-bubble px-3 py-2 rounded-xl">
        <div
          class="markdown hidden opacity-100 transition-all duration-200 starting:opacity-0"
          phx-hook="Message"
          data-role="user"
          data-content-id={@message.content_id}
          data-message-cache-key={@message_cache_key}
          id={@id}
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
      <div class="px-3 py-2 w-full">
        <div
          class="markdown hidden opacity-100 transition-all duration-200 starting:opacity-0 w-full"
          phx-hook="Message"
          data-role="assistant"
          data-content-id={@message.content_id}
          data-message-cache-key={@message_cache_key}
          data-message-id={@message.public_id}
          data-status={@message.status}
          phx-update="ignore"
          id={@id}
          phx-no-format
        >{@message.content}</div>
      </div>
    </div>
    """
  end

  defp model_selector(assigns) do
    ~H"""
    <.menu title="Models" id="model-selector" class="w-full max-w-96">
      <:header>
        <.input
          type="search"
          value=""
          class="w-full block"
          name="model-search"
          id="model-search"
          autofocus
          autocomplete="off"
        />
      </:header>
      <ul id="model-selector-list" phx-hook="List" phx-update="stream" data-search="#model-search">
        <li
          :for={{id, model} <- @streams.models}
          id={id}
          data-list-item={model.name}
          class="my-1 flex gap-2 hover:bg-bismuth-700 rounded-md px-2 py-1"
        >
          <div class="flex-1">
            <.button
              type="button"
              variant="blank"
              phx-click="select-model"
              phx-value-model={id}
              popovertarget="model-selector"
              popovertargetaction="hide"
              class="text-left cursor-pointer"
            >
              {model.name}
            </.button>
          </div>
          <div>
            <div class="bg-red-500 rounded-full px-1 text-xs leading-6 min-w-6 text-white font-bold">
              {model.cost}
            </div>
          </div>
        </li>
      </ul>
    </.menu>
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
        phx-update="stream"
      >
        <li
          :for={{id, thread} <- @streams.threads}
          id={id}
          data-list-item={if(thread.title == "", do: "New Chat", else: thread.title)}
          class="block my-1 rounded-lg px-3 py-2 hover:bg-bismuth-700 flex gap-2 md:gap-4 items-center"
        >
          <div class="flex-1">
            <.button
              navigate={~p"/thread/#{thread.public_id}"}
              variant="blank"
              class="text-left flex flex-col"
            >
              <div>
                {if(thread.title == "", do: "New Chat", else: thread.title)}
              </div>
              <div class="text-zinc-400 text-sm">
                Last message: {thread.last_active_at}
              </div>
            </.button>
          </div>
          <div class="flex items-center">
            <.button
              type="button"
              variant="toolbar"
              aria-label="Delete thread"
              popovertarget={"#{thread.public_id}-confirm-delete"}
            >
              <.icon name="hero-trash" class="size-5 md:size-4" />
            </.button>
          </div>
          <.alert id={"#{thread.public_id}-confirm-delete"} title="Confirm Delete">
            Are you sure you want to delete <strong>{if(thread.title == "", do: "New Chat", else: thread.title)}</strong>?
            This action is permanent and cannot be undone.
            <:action>
              <.button
                type="button"
                variant="link"
                autofocus
                popovertarget={"#{thread.public_id}-confirm-delete"}
                popovertargetaction="hide"
              >
                Cancel
              </.button>
            </:action>
            <:action>
              <.button
                type="button"
                variant="primary"
                phx-click="delete-thread"
                phx-value-id={thread.public_id}
              >
                Permanently Delete
              </.button>
            </:action>
          </.alert>
        </li>
      </ul>
    </.dialog>
    """
  end

  def handle_event("delete-thread", %{"id" => id}, socket) do
    %{current_scope: scope, thread: current_thread} = socket.assigns

    {count, _} =
      Repo.delete_all(
        from thread in Thread,
          where: thread.public_id == ^id and thread.user_id == ^scope.user.id
      )

    {:noreply,
     if current_thread != nil && current_thread.public_id == id && count == 1 do
       push_navigate(socket, to: ~p"/thread/new")
     else
       socket
     end
     |> stream_delete_by_dom_id(:threads, id)}
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
    scope = socket.assigns.current_scope

    model = Chat.Inference.select_model(:completion, scope)

    {:ok, thread} = Threads.create_thread(scope, model, %{title: ""})
    scope = Map.put(scope, :thread, thread)

    {:ok, user_message} =
      Threads.create_message(scope, model, %{role: :user, content: suggestion, status: :done})

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

    {:ok, thread} = Threads.create_thread(scope, model, %{title: ""})

    socket
    |> assign(thread: thread, current_scope: Map.put(scope, :thread, thread))
    |> push_navigate(to: ~p"/thread/#{thread.public_id}")
    |> prompt(prompt)
  end

  defp prompt(%{assigns: %{thread: %Thread{}}} = socket, prompt) do
    scope = socket.assigns.current_scope

    model = Chat.Inference.select_model(:completion, scope)

    content_id =
      prompt
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.encode16(case: :lower)

    {:ok, user_message} =
      Threads.create_message(scope, model, %{
        role: :user,
        content: prompt,
        status: :done,
        content_id: content_id
      })

    ChatWeb.ThreadServer.chat_completion(scope, user_message, model)

    socket
  end

  def mount(_params, _session, socket) do
    %{current_scope: scope} = socket.assigns

    ChatWeb.ThreadSupervisor.ensure_thread_server_started(scope.user)

    Threads.subscribe_threads(scope)

    models = Models.list_models(scope)
    threads = Threads.list_threads(scope)

    message_cache_key = Application.fetch_env!(:chat, :message_cache_key)

    {:ok,
     socket
     |> assign_form(changeset(%{}))
     |> assign(message_count: 0, message_cache_key: message_cache_key)
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

          # FIXME: prevent the doulbe event submission
          socket
          |> push_event("update-completion:#{assistant_message.public_id}", event_data)
      end

    {:noreply,
     socket
     |> assign(
       thread: thread,
       message_count: length(messages),
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
    {:noreply,
     socket
     |> stream_insert(:messages, message)
     |> push_event("created-message", %{"message_id" => message.public_id, "role" => message.role})}
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
