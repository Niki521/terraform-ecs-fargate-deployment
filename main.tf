provider "aws" {
  region = "ap-south-1" # Change this to your desired AWS region
}


resource "aws_ecs_cluster" "cluster_test_niki" {
  name = "my-cluster-niki"
  tags = {
    name  =  xyz
  }
}



resource "aws_ecs_task_definition" "task_definition_niki" {
  family                   = "nginx-example"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "0.5GB"
  execution_role_arn = <ARN_of_role>

  container_definitions = jsonencode([{
    name  = "nginx-example"
    image = "nginx:latest" # You can use any Nginx image you prefer
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
}])

  tags = {
    name  =  xyz
  }
}

resource "aws_ecs_service" "ecs_service_niki" {
  name            = "nginx-service-niki"
  cluster         = aws_ecs_cluster.cluster_test_niki.id
  task_definition = aws_ecs_task_definition.task_definition_niki.arn
  #launch_type     = "FARGATE"
  desired_count = 2
  capacity_provider_strategy {
      capacity_provider = "FARGATE_SPOT"
      weight            = 100
  }
  network_configuration {
    subnets = ["subnet-************] # Replace with your subnet IDs
    security_groups = ["sg-***************"] # Replace with your security group IDs
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = <ARN_of_target_group>
    container_name = "nginx-example"
    container_port = 80
  }
  depends_on = [aws_ecs_cluster.cluster_test_niki]
  tags = {
    name  =  xyz
  }
  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.cluster_test_niki.name}/${aws_ecs_service.ecs_service_niki.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  tags = {
    name  =  xyz
  }
}

resource "aws_appautoscaling_policy" "ecs_scaling_policy" {
  name               = "ecs-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace = aws_appautoscaling_target.ecs_target.service_namespace

 

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 10  # Update with your desired target CPU utilization percentage
    scale_in_cooldown  = 15
    scale_out_cooldown = 15
    disable_scale_in = false
  }
}
