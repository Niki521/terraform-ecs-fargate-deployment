provider "aws" {
  region = "ap-south-1" # Change this to your desired AWS region
}


resource "aws_ecs_cluster" "cluster_test_niki" {
  name = "my-cluster-niki"
  tags = {
    Owner = "niki.bhanushali@einfochips.com"
    DM = "Rajeev Padinharepattu"
    Department = "PES" 
    Project_Name = "Echonous"
    BU = "Digital"
  }
}



resource "aws_ecs_task_definition" "task_definition_niki" {
  family                   = "nginx-example"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "0.5GB"
  execution_role_arn = "arn:aws:iam::454143665149:role/ecsTaskExecutionRole"

  container_definitions = jsonencode([{
    name  = "nginx-example"
    image = "nginx:latest" # You can use any Nginx image you prefer
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
}])

  tags = {
    Owner = "niki.bhanushali@einfochips.com"
    DM = "Rajeev Padinharepattu"
    Department = "PES" 
    Project_Name = "Echonous"
    BU = "Digital"
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
    subnets = ["subnet-0543649ff7096d321","subnet-016e36591146bc3d2","subnet-032abef31055eb40c","subnet-01702df93ad2d6a05"] # Replace with your subnet IDs
    security_groups = ["sg-0c66969f7206ce59b"] # Replace with your security group IDs
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = "arn:aws:elasticloadbalancing:ap-south-1:454143665149:targetgroup/ECS-Targetgroup-niki/2948a68a80d92427"
    container_name = "nginx-example"
    container_port = 80
  }
  depends_on = [aws_ecs_cluster.cluster_test_niki]
  tags = {
    Owner = "niki.bhanushali@einfochips.com"
    DM = "Rajeev Padinharepattu"
    Department = "PES" 
    Project_Name = "Echonous"
    BU = "Digital"
  }
  lifecycle {
    ignore_changes = [desired_count]
  }
}

# resource "aws_ecs_cluster_capacity_providers" "ecs_cluster_niki" {
#   cluster_name = aws_ecs_cluster.cluster_test_niki.name

#   capacity_providers = ["FARGATE","FARGATE_SPOT"]

#   default_capacity_provider_strategy {
#     base              = 1
#     weight            = 100
#     capacity_provider = "FARGATE_SPOT"
#   }
# }

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.cluster_test_niki.name}/${aws_ecs_service.ecs_service_niki.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  tags = {
    Owner = "niki.bhanushali@einfochips.com"
    DM = "Rajeev Padinharepattu"
    Department = "PES" 
    Project_Name = "Echonous"
    BU = "Digital"
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
    # Step adjustments with and without upper bounds
    # step_adjustment {
    #   metric_interval_lower_bound = 0
    #   metric_interval_upper_bound = 10  # Change this value as needed
    #   scaling_adjustment          = 1   # Adjust the count for scale-out
    # }
    # step_adjustment {
    #   metric_interval_lower_bound = 0
    #   scaling_adjustment          = 1    # Adjust the count for scale-out
    # }
  }
}

# resource "aws_appautoscaling_policy" "ecs_scale_out_policy" {
#   name               = "scale-out"
#   policy_type        = "StepScaling"
#   resource_id        = aws_appautoscaling_target.ecs_target.resource_id
#   scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

#   step_scaling_policy_configuration {
#     adjustment_type         = "ChangeInCapacity"
#     cooldown                = 60
#     metric_aggregation_type = "Average"

#     step_adjustment {
#       metric_interval_lower_bound = 0
#       metric_interval_upper_bound = 100
#       scaling_adjustment          = 1
#     }
#   }

#   step_scaling_policy_configuration {
#     adjustment_type         = "ChangeInCapacity"
#     cooldown                = 60
#     metric_aggregation_type = "Average"

#     step_adjustment {
#       metric_interval_upper_bound = 0
#       scaling_adjustment          = -1
#     }

#   }
# }

# resource "aws_appautoscaling_policy" "ecs_scale_in_policy" {
#   name               = "scale-down"
#   policy_type        = "StepScaling"
#   resource_id        = aws_appautoscaling_target.ecs_target.resource_id
#   scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace


#   step_scaling_policy_configuration {
#     adjustment_type         = "ChangeInCapacity"
#     cooldown                = 60
#     metric_aggregation_type = "Maximum" 

#     step_adjustment {
#       metric_interval_upper_bound = 0
#       scaling_adjustment          = -1
#     }
#   }
# }
# Scaling Out Configuration
# # # resource "aws_appautoscaling_policy" "ecs_scale_policy" {
# # #   name               = "scale-policy"
# # #   policy_type        = "StepScaling"
# # #   resource_id        = aws_appautoscaling_target.ecs_target.resource_id
# # #   scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
# # #   service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

# # #   step_scaling_policy_configuration {
# # #     adjustment_type         = "ChangeInCapacity"
# # #     cooldown                = 60
# # #     metric_aggregation_type = "Average"

# # #     step_adjustment {
# # #       metric_interval_lower_bound = 1.0
# # #       metric_interval_upper_bound = 2.0
# # #       scaling_adjustment          = -1
# # #     }

# # #     step_adjustment {
# # #       metric_interval_lower_bound = 2.0
# # #       #metric_interval_upper_bound = 3.0
# # #       scaling_adjustment          = 1
# # #     }
# # #   }
# # # }

#Scaling In Configuration
# resource "aws_appautoscaling_policy" "ecs_scale_out_policy" {
#   name               = "scale-out"
#   policy_type        = "StepScaling"
#   resource_id        = aws_appautoscaling_target.ecs_target.resource_id
#   scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

#   step_scaling_policy_configuration {
#     adjustment_type         = "ChangeInCapacity"
#     cooldown                = 60
#     metric_aggregation_type = "Average"

#     step_adjustment {
#       metric_interval_lower_bound = 2.0
#       scaling_adjustment          = 1
#     }
#   }
# }




# resource "aws_ecs_capacity_provider" "ecs_capacity_niki" {
#   name = "ecs_capacity_provider_niki"

#   auto_scaling_group_provider {
#     auto_scaling_group_arn         = "arn:aws:autoscaling:ap-south-1:454143665149:autoScalingGroup:99b58d98-6ed7-40c5-924e-3cdea0579d7f:autoScalingGroupName/ECS-Test-Niki"
#     managed_termination_protection = "ENABLED"

#     managed_scaling {
#       maximum_scaling_step_size = 1000
#       minimum_scaling_step_size = 1
#       status                    = "ENABLED"
#       target_capacity           = 10
#     }
#   }
# }

