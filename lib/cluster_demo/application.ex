defmodule ClusterDemo.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies)

    children = [
      {Cluster.Supervisor, [topologies, [name: ClusterDemo.ClusterSupervisor]]}
    ]

    opts = [strategy: :one_for_one, name: ClusterDemo.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
