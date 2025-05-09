defmodule ClusterDemo.NodeLogger do
  use GenServer
  require Logger

  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  def init(_) do
    :net_kernel.monitor_nodes(true)
    Logger.info("Started node: #{inspect(Node.self())}")
    {:ok, nil}
  end

  def handle_info({:nodeup, node}, state) do
    Logger.info("Node joined: #{inspect(node)}")
    {:noreply, state}
  end

  def handle_info({:nodedown, node}, state) do
    Logger.warning("Node left: #{inspect(node)}")
    {:noreply, state}
  end
end
