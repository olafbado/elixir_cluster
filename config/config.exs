import Config

if config_env() == :dev do
  # to test it locally, open a terminal and run:
  # iex --sname a -S mix
  # iex --sname b -S mix

  config :libcluster,
    topologies: [
      local_gossip: [
        strategy: Cluster.Strategy.Gossip
      ]
    ]
end
