import Config

if config_env() == :dev do
  config :libcluster,
    topologies: [
      local_gossip: [
        strategy: Cluster.Strategy.Gossip
      ]
    ]
end
