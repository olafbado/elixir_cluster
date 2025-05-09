import Config

config :libcluster,
  topologies: [
    local_gossip: [
      strategy: Cluster.Strategy.Gossip
    ]
  ]
