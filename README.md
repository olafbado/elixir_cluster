# Elixir Clustering: Local → Local Docker -> ECS EC2 → ECS Fargate

## 🌟 Goal

Test and validate Elixir node clustering using `libcluster`, starting locally, then with Docker, and finally deploying to ECS (EC2 and Fargate).

## 💻 Local IEx Clustering

Open two terminals and run:

```bash
iex --sname a -S mix
iex --sname b -S mix
```

In either IEx shell, run:

```elixir
Node.list()
```

## 🐳 Docker-Based Local Clustering

### 🔧 1. Build Docker image

```bash
docker build -t cluster_demo .
```

### 🔧 2. Create a shared Docker network

```bash
docker network create cluster_demo_net
```

### 🔧 3. Run containers in the same network

```bash
docker run -it --network cluster_demo_net -p 1234:4000 cluster_demo
```

In another terminal:

```bash
docker run -it --network cluster_demo_net -p 1235:4000 cluster_demo
```

Connect to the first container:

```bash
docker ps                            # find container ID
docker exec -it <container_id> /bin/bash   # connect to container shell
bin/cluster_demo remote
```
Then in IEx:

```elixir
Node.list()
```

## 📦 Next Steps

* ✅ Deploy to ECS EC2 with `libcluster` EC2 strategy (based on instance tags)
* 🔜 Deploy to ECS Fargate with `libcluster` DNS strategy (via service discovery)
