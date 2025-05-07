defmodule ChatWeb.ThreadSupervisor do
  use DynamicSupervisor

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def ensure_thread_server_started(user) do
    registry_name_tuple = ChatWeb.ThreadServer.via_tuple(user)
    child_supervisor_id = :"thread_server_#{user.id}"

    case GenServer.whereis(registry_name_tuple) do
      pid when is_pid(pid) ->
        {:ok, pid}

      nil ->
        child_spec = %{
          id: child_supervisor_id,
          start: {ChatWeb.ThreadServer, :start_link, [user]}
        }

        case DynamicSupervisor.start_child(__MODULE__, child_spec) do
          {:ok, pid} ->
            {:ok, pid}

          {:ok, pid, _child_info} ->
            {:ok, pid}

          {:error, {:already_started, pid}} ->
            {:ok, pid}

          {:error, reason} ->
            case Process.whereis(registry_name_tuple) do
              pid when is_pid(pid) ->
                {:ok, pid}

              nil ->
                {:error, reason}
            end
        end
    end
  end
end
