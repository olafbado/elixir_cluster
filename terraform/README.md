# ecs.tf

In this file, we create complete ECS enviroment with type Fargate.
We also setup service discovery with DNS so containers can see each other.

## 📦 Components & Pricing Summary

### 1. VPC Module

Creates:

- `aws_vpc` – definiuje naszą sieć prywatną w AWS (jak domowa sieć LAN)  
  ✅ Free

- `aws_internet_gateway` – umożliwia połączenie VPC z internetem (działa jak router)  
  ✅ Free (płacisz tylko za transfer danych)

- `aws_default_security_group` – firewall działający na poziomie instancji (np. EC2, ECS)  
  ✅ Free

---

### 2. Dynamic Subnets Module

Tworzy (dla każdej Availability Zone):

- `aws_subnet.public` – publiczny subnet z dostępem do internetu  
  ✅ Free

- `aws_subnet.private` – prywatny subnet (bez bezpośredniego dostępu z internetu)  
  ✅ Free

- `aws_nat_gateway` – pozwala zasobom z prywatnych subnetów wychodzić do internetu  
  ⚠️ ~$0.045/h (~$32/miesięcznie) + $0.045/GB outbound data  
  💡 Drogi – domyślnie tworzony dla każdej AZ, można ograniczyć do 1

- `aws_eip` (Elastic IP) – statyczny publiczny IP dla NAT Gateway  
  ✅ Free jeśli używany  
  ❗️Płatny jeśli nieużywany

- `aws_route_table` & `aws_route` – wskazują gdzie kierować ruch sieciowy (np. do IGW/NAT)  
  ✅ Free

- `aws_network_acl` & `aws_network_acl_rule` – firewall działający na poziomie subnetu  
  ✅ Free

### 3. Private DNS namespace and discovery service

To prywatna domena DNS (namespace), którą tworzysz w AWS Route 53 za pomocą Cloud Map. 
Umożliwia ona rozwiązywanie nazw DNS (np. api.myapp.local) do IP kontenerów (tasków ECS), ale tylko wewnątrz Twojej VPC.

CloudMap will create namespace ie. hosted zone in Route 53. Then we need to add a service that is mapped as
Route53 record.

We create disovery service that will be used to map our ECS services to created namespace

### 4. Application Load Balancer (ALB) Module

Tworzy:

- **`aws_lb`** – Application Load Balancer (ALB), publiczny (umieszczony w public subnet), typ `application`
  ⚠️ Koszt: ok. **$0.025–0.03/h** + opłaty za transfer danych

- **`aws_lb_listener`** – nasłuchuje na porcie 80 i przekierowuje ruch do backendu  
  ✅ Free

- **`aws_lb_target_group`** – grupa docelowa, do której ALB przekazuje ruch  
  ✅ Free

- **`aws_security_group`** – grupa bezpieczeństwa dla ALB  
  - Kontroluje dostęp do ALB z zewnątrz  
  - Zezwala na ruch HTTP (port 80) z Internetu (`0.0.0.0/0`)  
  ✅ Free

- **`aws_security_group_rule`** – reguły:  
  - `ingress`: TCP 80 z `0.0.0.0/0`  
  - `egress`: cały ruch (`0.0.0.0/0`)  
  ✅ Free


### Module web

### 1. ECS Cluster i Task

- **`aws_ecs_cluster`**  
  Tworzy klaster ECS (`elixir_cluster`)  
  ✅ Free

- **`aws_ecs_service`**  
  Uruchamia kontener jako usługę ECS Fargate  
  🔄 Zintegrowany z ALB + Cloud Map  
  💰 Płacisz za zasoby Fargate (np. 256 CPU / 512 MB RAM ≈ ~$15/miesiąc per task)

- **`aws_ecs_task_definition`**  
  Definicja taska (CPU, RAM, porty, obraz Dockera)  
  ✅ Free

### 2. Networking

- **`network_configuration.subnets`**  
  ECS działa w prywatnych subnetach (z dostępem do internetu przez NAT Gateway)

- **`assign_public_ip = false`**  
  Brak publicznego IP – dostęp przez NAT

- **`aws_security_group`**  
  Domyślnie zezwala na outbound ruch do 0.0.0.0/0  
  ✅ Free

### 3. Load Balancer (ALB)

- **`aws_lb_target_group`**  
  Przekazuje ruch HTTP (port `4000`) do kontenerów ECS  
  🔄 Health check: `/`, co 15s  
  ✅ Free
- ECS Service automatycznie rejestruje taski w target group

### 4. Service Discovery

- **`service_registries` + Cloud Map**  
  ECS taski rejestrowane w prywatnym namespace  
  🔎 Przykład DNS: `web.namespace.local`  
  🛡️ Widoczne tylko wewnątrz VPC  
  ✅ Free

### 5. ECR (Elastic Container Registry)

- **`aws_ecr_repository`**  
  Repozytorium Docker dla Twojego obrazu  
  ✅ Free (płacisz tylko za storage)

- **`aws_ecr_lifecycle_policy`**  
  Auto-usuwanie starych/nieoznakowanych obrazów  
  ✅ Free

### 6. Logi

- **`aws_cloudwatch_log_group`**  
  Logi kontenerów – retention 90 dni  
  ✅ Free do 5GB/mies., potem ~$0.50/GB

### 7. IAM Roles i Policies

- **Role dla ECS:**
  - `ecs_task`
  - `ecs_exec` (dla `exec-command`)
- **Dostęp do logów, ECR, SSM itp.**  
  ✅ Free