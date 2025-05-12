# ECS & Clustering – Notes

### 📦 Locally: Build & Deploy to ECS
1. Build docker image !!! REMEMBER ABOUT ARCH, USE DOCKERX IF NEEDED !!!
`docker build -t <image_name> .`
2. Tag docker image
`docker tag <image_name>:latest 387343693864.dkr.ecr.<region>.amazonaws.com/<image_name>:latest`
3. Login to ECR
`aws ecr get-login-password --profile <profile> --region <region> | docker login --username AWS --password-stdin 387343693864.dkr.ecr.<region>.amazonaws.com`
4. Push image to ECT
`docker push 387343693864.dkr.ecr.<region>.amazonaws.com/<image_name>:latest`
5. Create ECS cluster with EC2 type (remember about correct instance type so it has sufficient cpu and ram!)
6. Create `Task Definition` with docker image → then Create Service and launch tasks

### 🔍 How to debug ECS?
1. Check ECR region – ensure the image is in the same region as ECS cluster
2. Can't SSH to EC2? – check security groups and inbound rules (port 22, your IP)
3. Verify EC2 is in ECS cluster via `curl http://localhost:51678/v1/metadata → Should include a Cluster key
4. Check if EC2 and tasks are listed under `Infrastructure` tab in cluster settings.
5. Check task definition and ec2 resources ie. cpu, ram, ports

### 🌐 Testing Elixir Node Connectivity (manual)
1. Run 2 tasks (can be in the same EC2)
2. Ensure the `:erlang.get_cookie()` value is the same for both
3. Connect nodes via `Node.connect(:"cluster_demo@ip-172-31-45-214")`
4. Try `Node.list()`, it should list nodes

### 🧭 Discovery via Private DNS
1. Enable Service Discovery in ECS service (Cloud Map)
2. On node and conteiner use `nslookup test.cluster_demo`  or `getent hosts test.cluster_demo`
3. Elixir + libcluster will use this DNS to connect nodes automatically

### 📦 ECS – Mental Model

ECS lets you run Docker containers and scale based on task count, ensures the desired number of containers is running

### Task Definition
A template that describes how to run a container.  
It includes things like the Docker image, environment variables, exposed ports, CPU/memory limits, etc.

### Task
A single running instance of a Task Definition — i.e. one container.

### Cluster
A group of resources (e.g. EC2 instances or Fargate) where tasks are run.  

### Service
A controller that manages the number of running tasks.  
It ensures the desired count is met, handles scaling, and optionally registers tasks in private DNS  
(e.g. via Cloud Map).

# Service Discovery in ECS

## What it solves
In ECS, tasks (containers) get new IPs every time they're restarted or scaled. We need a way for them to find each other without hardcoding IPs.

## Core idea
We register tasks under a fixed DNS name using `Cloud Map`, so containers can resolve and connect to each other dynamically.


## Key components

| Component       | What it does                                               |
|----------------|-------------------------------------------------------------|
| Task Definition| Describes how to run the container                          |
| Task           | One running container                                       |
| Cluster        | Where tasks run (e.g. EC2 or Fargate)                       |
| Service        | Keeps the desired number of tasks running                   |
| Cloud Map      | Registers each running task under a DNS name               |
| Route 53       | Private DNS that maps names to task IPs                    |
| libcluster     | Uses DNS to discover and connect to other Elixir nodes     |


## How it works

1. Create a `Private DNS namespace` (e.g. `cluster_demo`)
2. ECS Service is set to register tasks under a name (e.g. `test.cluster_demo`)
3. ECS starts tasks and adds their IPs to DNS via Cloud Map
4. Containers can query:
   ```bash
   getent hosts test.cluster_demo
   ```
   and get the current task IPs
5. Elixir uses libcluster to connect nodes using that DNS name

## Summary

ECS + Cloud Map + DNS lets your containers discover each other using a shared name. That’s all libcluster needs to form a cluster automatically.