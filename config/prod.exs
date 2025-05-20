import Config

config :libcluster,
  topologies: [
    dns_poll: [
      strategy: Cluster.Strategy.DNSPoll,
      config: [
        polling_interval: 5_000,
        # <service_name>.<namespace>
        query: "elixir_cluster.elixir_cluster",
        # on the left of @
        node_basename: "elixir_cluster",
      ]
    ]
  ]
