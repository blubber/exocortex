defmodule ChatWeb.ThreadServer.Request do
  defstruct [
    :request_id,
    :requestor_pid,
    :scope,
    :user_message,
    :assistant_message,
    :chunks
  ]
end

defmodule ChatWeb.ThreadServer do
  use(HTTPoison.Base)
  use GenServer

  alias Chat.Completion
  alias ChatWeb.ThreadServer.Request
  alias Chat.Accounts.{Scope, User}
  alias Chat.Threads
  alias Chat.Threads.Thread

  def chat_completion(
        %Scope{thread: %Thread{}, user: %User{} = user} = scope,
        user_message,
        model
      ) do
    GenServer.call(via_tuple(user), {:chat_completion, scope, user_message, model})
  end

  def chunks(%Scope{thread: %Thread{}, user: %User{} = user} = scope) do
    GenServer.call(via_tuple(user), {:chunks, scope.thread})
  end

  def prepare_thread(%Scope{thread: %Thread{}, user: %User{} = user} = scope) do
    GenServer.call(via_tuple(user), {:prepare_thread, scope})
  end

  def start_link(user) do
    GenServer.start_link(__MODULE__, user, name: via_tuple(user))
  end

  def via_tuple(user) do
    {:via, Registry, {ChatWeb.ThreadRegistry, user.id}}
  end

  def init(_user) do
    {:ok, %{}}
  end

  def handle_call({:prepare_thread, scope}, _from, state) do
    if find(scope, state) == nil do
      Threads.reset_thread(scope, scope.thread)
    end

    {:reply, :ok, state}
  end

  def handle_call({:chunks, %Thread{} = thread}, _from, state) do
    {:reply,
     case find(thread, state) do
       nil ->
         nil

       %Request{} = request ->
         {request.assistant_message, Enum.with_index(Enum.reverse(request.chunks))}
     end, state}
  end

  def handle_call({:chat_completion, scope, user_message, model}, {pid, _ref}, state) do
    # FIXME: Prevent multiple requests for the same thread
    {:ok, assistant_message} =
      Threads.create_message(scope, model, %{
        role: :assistant,
        status: :processing,
        content: ""
      })

    model = Chat.Repo.preload(model, :model_provider)

    messages =
      scope
      |> Threads.query_messages()
      |> Threads.filter_context()
      |> Threads.list_messages()

    {url, headers} = Completion.prepare_request(model)
    body = Completion.prepare_body(model, messages)

    with {:ok, body_data} <- Jason.encode(body),
         {:ok, %HTTPoison.AsyncResponse{id: id}} <-
           post(url, body_data, headers,
             stream_to: self(),
             timeout: 15_000,
             recv_timeout: 300_000
           ) do
      request = %Request{
        request_id: id,
        requestor_pid: pid,
        scope: scope,
        user_message: user_message,
        assistant_message: assistant_message,
        chunks: []
      }

      {:reply, request, Map.put(state, id, request)}
    else
      {:error, reason} ->
        Threads.update_message(scope, assistant_message, %{
          status: :failed,
          reason: Exception.message(reason)
        })

        {:reply, {:error, reason}, state}

      _ ->
        Threads.update_message(scope, assistant_message, %{status: :failed, reason: "unknown"})
        {:reply, {:error, :unknown}, state}
    end
  end

  def handle_info(%HTTPoison.AsyncStatus{id: id}, state)
      when not is_map_key(state, id) do
    :hackney.stop_async(id)
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncStatus{id: id, code: code}, state) do
    if code >= 300 do
      :hackney.stop_async(id)

      request = state[id]

      Threads.update_message(request.scope, request.assistant_message, %{
        status: :failed,
        reason: "non-200 http status code: #{code}"
      })

      {:noreply, Map.delete(state, id)}
    else
      {:noreply, state}
    end
  end

  def handle_info(%HTTPoison.AsyncHeaders{id: id}, state) when not is_map_key(state, id) do
    :hackney.stop_async(id)
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncHeaders{}, state) do
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncChunk{id: id}, state) when not is_map_key(state, id) do
    :hackney.stop_async(id)
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncChunk{id: id, chunk: chunk}, state) do
    request = state[id]

    chunks = Completion.parse_chunk(chunk)

    chunks
    |> Enum.with_index(length(request.chunks))
    |> Enum.each(
      &Threads.broadcast(
        request.scope,
        {:update_completion, request.assistant_message, &1}
      )
    )

    {:noreply,
     Map.update(state, id, nil, fn request ->
       %Request{request | chunks: Enum.reverse(chunks) ++ request.chunks}
     end)}
  end

  def handle_info(%HTTPoison.AsyncEnd{id: id}, state) when not is_map_key(state, id) do
    :hackney.stop_async(id)
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncEnd{id: id}, state) do
    %{
      user_message: user_message,
      assistant_message: assistant_message,
      chunks: chunks,
      scope: scope
    } =
      state[id]

    content =
      chunks
      |> Enum.map(& &1.content)
      |> Enum.reverse()
      |> Enum.join()

    content_id =
      content
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.encode16(case: :lower)

    {input_tokens, output_tokens} =
      chunks
      |> Enum.reduce({0, 0}, fn chunk, {input_tokens, output_tokens} ->
        {input_tokens + chunk.input_tokens, output_tokens + chunk.output_tokens}
      end)

    Threads.update_message(scope, user_message, %{token_count: input_tokens})

    Threads.update_message(scope, assistant_message, %{
      content: content,
      content_id: content_id,
      status: :done,
      token_count: output_tokens
    })

    {:noreply, Map.delete(state, id)}
  end

  def handle_info(%HTTPoison.Error{id: id}, state)
      when not is_map_key(state, id) do
    :hackney.stop_async(id)
    {:noreply, state}
  end

  def handle_info(%HTTPoison.Error{id: id} = error, state) do
    request = state[id]

    Threads.update_message(request.scope, request.assistant_message, %{
      status: :failed,
      reason: Exception.message(error)
    })

    :hackney.stop_async(id)
    {:noreply, Map.delete(state, id)}
  end

  defp find(%Thread{} = thread, state) do
    case Enum.find(state, fn {_, request} ->
           request.user_message.thread_id == thread.id
         end) do
      nil -> nil
      {_, request} -> request
    end
  end

  defp find(%Scope{thread: %Thread{} = thread}, state) do
    find(thread, state)
  end
end
