import Config

config :libcluster,
  topologies: [
    dns_poll: [
      strategy: Cluster.Strategy.DNSPoll,
      config: [
        polling_interval: 5_000,
        # <service_name>.<namespace>
        query: "elixir_cluster.elixir_cluster",
        # set by the RELEASE_NODE env var
        node_basename: "elixir_cluster",
        record_type: :a
      ]
    ]
  ]
