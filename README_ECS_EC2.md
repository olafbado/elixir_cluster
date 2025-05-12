Defining process for ECS EC2 cluster.

1. Create AWS ECR
aws ecr get-login-password --region us-east-2 --profile admin | docker login --username AWS --password-stdin 387343693864.dkr.ecr.us-east-2.amazonaws.com
2. Build docker image
docker build -t <image_name> .
3. tag docker image
docker tag cluster_demo:latest 387343693864.dkr.ecr.us-east-2.amazonaws.com/cluster_demo:latest
4. Push to ECR
docker push 387343693864.dkr.ecr.us-east-2.amazonaws.com/cluster_demo:latest
5. Create ECS cluster