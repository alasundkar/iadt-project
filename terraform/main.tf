provider "aws" {
    region = var.region
}

resource "aws_vpc" "selected" {
    cidr_block = var.cidr
    enable_dns_hostnames = true
    enable_dns_support = true
    assign_generated_ipv6_cidr_block = false
    enable_classiclink_dns_support = true

    tags = {
        Name = "IAD-vpc"
    }
}

data "aws_availability_zones" "available" {
    state = "available"
}


resource "aws_subnet" "primary-subnet" {
    availability_zone = data.aws_availability_zones.available.names[0]
    vpc_id            = aws_vpc.selected.id
    cidr_block = var.subnet_cidr_primary
    map_public_ip_on_launch = true

    tags = {
        Name = "IAD-subnet-primary"
    }
}

resource "aws_subnet" "secondary-subnet" {
    availability_zone = data.aws_availability_zones.available.names[1]
    vpc_id            = aws_vpc.selected.id
    cidr_block = var.subnet_cidr_secondary
    map_public_ip_on_launch = true

    tags = {
        Name = "IAD-subnet-secondary"
    }
}

resource "aws_subnet" "third-subnet" {
    availability_zone       = data.aws_availability_zones.available.names[2]
    vpc_id                  = aws_vpc.selected.id
    cidr_block              = var.subnet_cidr_third
    map_public_ip_on_launch = true

    tags = {
        Name = "IAD-subnet-third"
    }
}

resource "aws_subnet" "fourth-subnet" {
    availability_zone       = data.aws_availability_zones.available.names[1]
    vpc_id                  = aws_vpc.selected.id
    cidr_block              = var.subnet_cidr_fourth

    tags = {
        Name = "IAD-subnet-fourth"
    }
}

resource "aws_internet_gateway" "vpc_gway" {
  vpc_id = aws_vpc.selected.id

  tags = {
    Name = "internet-gateway"
  }
}

#Route Table for VPC
resource "aws_route_table" "routetable" {
    vpc_id = aws_vpc.selected.id
}

#Default Route for the above route table
resource "aws_route" "default_route" {
    route_table_id = aws_route_table.routetable.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_gway.id
     depends_on = [
        aws_route_table.routetable,
        aws_internet_gateway.vpc_gway
    ]
}

#Attaching primary subnet to route table
resource "aws_route_table_association" "priamry-routetable-association" {
    subnet_id = aws_subnet.primary-subnet.id
    route_table_id = aws_route_table.routetable.id
}

#Attaching secondary subnet to route table
resource "aws_route_table_association" "secondary-routetable-association" {
    subnet_id = aws_subnet.secondary-subnet.id
    route_table_id = aws_route_table.routetable.id
}

#Attaching third subnet to route table
resource "aws_route_table_association" "third-routetable-association" {
    subnet_id = aws_subnet.third-subnet.id
    route_table_id = aws_route_table.routetable.id
}

#Attaching fourth subnet to route table
resource "aws_route_table_association" "fourth-routetable-association" {
    subnet_id = aws_subnet.fourth-subnet.id
    route_table_id = aws_route_table.routetable.id
}

#Attaching Security Group to EC2 instance
resource "aws_security_group" "application_sec_grp" {
  name        = "application_sec_grp"
  description = "Setting inbound and outbound traffic"
  vpc_id      = aws_vpc.selected.id


  ingress {
    description = "Http for VPC"
    from_port   = 80
    to_port     = 80
    protocol    = 6
    security_groups = [aws_security_group.load_balancer_sec_grp.id]
  }

  ingress {
    description = "Port for application"
    from_port   = var.port2
    to_port     = var.port2
    protocol    = "tcp"
    security_groups = [aws_security_group.load_balancer_sec_grp.id]
  }



  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_block_sec_grp_outbound]
  }

  tags = {
    Name = "application_sec_grp"
  }
}

#Creating DB Security for RDS
resource "aws_security_group" "database_sec_grp" {
  name        = "database_sec_grp"
  description = "Setting inbound and outbound traffic"
  vpc_id      = aws_vpc.selected.id

  ingress {
    description = "Database port for webapp"
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    security_groups = [aws_security_group.application_sec_grp.id]
  }

  tags = {
    Name = "database_sec_grp"
  }
}

#Creating a subnet group for RDS instance
resource "aws_db_subnet_group" "rds_db_subnet_grp" {
  name       = "rds_db_subnet_grp"
  subnet_ids = [aws_subnet.fourth-subnet.id,aws_subnet.third-subnet.id]

  tags = {
    Name = "My DB subnet group"
  }
}


data "aws_ami" "ubuntu" {
  most_recent = true
  name_regex = "^IAD_.*"
  owners = [var.ami_owner]
}

#Creating role for S3 access
resource "aws_iam_role" "S3AccessRole" {
  name = "S3AccessRole"

  assume_role_policy = file("ec2s3role.json")
  
  tags = {
    Name = "EC2-S3-Access IAM role"
  }
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.S3AccessRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

#Profile for attachment to EC2 instance
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.S3AccessRole.name
}


#------------------------------------- Launch Configuration --------------------------------------
resource "aws_launch_configuration" "asg_launch_config" {
  name   = "asg_launch_config"
  image_id      = data.aws_ami.ubuntu.id 
  instance_type = "t2.micro"
  key_name = var.ssh_key_name
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  security_groups  = [aws_security_group.application_sec_grp.id] 
  
  root_block_device {
    volume_type           =  var.root_block_device_volume_type
    volume_size           =  var.root_block_device_volume_size
    delete_on_termination = true
  }

  depends_on = [
    aws_db_instance.rds_instance
  ] 
  user_data = <<-EOF
          #!/bin/bash
          sudo apt install python3-pip -y
          sudo pip install awscli 
          aws s3 sync  s3://iadtassgnment /home/ubuntu/.
          chmod +x /home/ubuntu/iadt_web_application/views.py
          pip3 install -r /home/ubuntu/iadt_web_application/requirements.txt
          echo export "AWS_ACCESS_KEY_ID=${var.access_key}" | sudo tee -a /etc/environment
          echo export "AWS_SECRET_ACCESS_KEY=${var.secret_key}" | sudo tee -a /etc/environment
          echo export "AWS_REGION=${var.region}" | sudo tee -a /etc/environment
          echo export "RDS_DBNAME=${var.rds_db}" | sudo tee -a /etc/environment
          echo export "RDSHOST_NAME=${aws_db_instance.rds_instance.address}" | sudo tee -a /etc/environment
          echo export "RDS_USERNAME=${var.db_master_username}" | sudo tee -a /etc/environment
          echo export "RDS_PASSWORD=${var.db_master_password}" | sudo tee -a /etc/environment
          pip3 install -r /home/ubuntu/iadt_web_application/requirements.txt
          export "RDS_USERNAME=${var.db_master_username}"
          export "RDSHOST_NAME=${aws_db_instance.rds_instance.address}"
          export "RDS_PASSWORD=${var.db_master_password}"
          source /etc/environment
          nohup python3 /home/ubuntu/iadt_web_application/views.py &
      EOF
}

#--------------------------------------- Security Group for Load Balancer --------------------------------

#Attaching Security Group to EC2 instance
resource "aws_security_group" "load_balancer_sec_grp" {
  name        = "load_balancer_sec_grp"
  description = "Setting inbound and outbound traffic for load balancer"
  vpc_id      = aws_vpc.selected.id

  ingress {
    description = "Http for VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "TCP"
    cidr_blocks = [var.cidr_block_sec_grp_http]
  } 

  ingress {
      description = "Http for VPC"
      from_port   = 443
      to_port     = 443
      protocol    = "TCP"
      cidr_blocks = [var.cidr_block_sec_grp_http]
  } 
 

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_block_sec_grp_outbound]
  }

  tags = {
    Name = "load_balancer_sec_grp"
  }
}


#--------------------------------------------- Load Balancer ----------------------------------------------

#Load Balancer for Webapp
resource "aws_lb" "webapp-load-balancer" {
  name               = "webapp-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_sec_grp.id]
  subnets            = [aws_subnet.primary-subnet.id, aws_subnet.secondary-subnet.id, aws_subnet.third-subnet.id]
  tags = {
    Name = "webapp-load-balancer"
  }
}

#Load Balancer Target Group for load balancer
resource "aws_lb_target_group" "target_group_lb_webapp" {
  name     = "target-group-lb-webapp"
  vpc_id   = aws_vpc.selected.id
  port     = 8080
  protocol = "HTTP"

}

resource "aws_lb_target_group" "target_group_lb_webapp_ssh" {
  name     = "target-group-lb-webapp-ssh"
  vpc_id   = aws_vpc.selected.id
  port     = 22
  protocol = "TCP"
}

#Load Balancer Listener
resource "aws_lb_listener" "lb_listener_2" {
  load_balancer_arn = aws_lb.webapp-load-balancer.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_lb_webapp.arn
  }
}

#--------------------------------------- Auto-Scaling Group ---------------------------------
resource "aws_autoscaling_group" "ag_ec2_instance" {
  name                      = "ag_ec2_instance"
  max_size                  = 5
  min_size                  = 1
  desired_capacity          = 1
  force_delete              = true
  launch_configuration      = aws_launch_configuration.asg_launch_config.name
  vpc_zone_identifier       = [aws_subnet.primary-subnet.id, aws_subnet.secondary-subnet.id, aws_subnet.third-subnet.id]
  target_group_arns         = [aws_lb_target_group.target_group_lb_webapp.arn]
  default_cooldown          = 60

  tag {
    key                 = "Name"
    value               = "IAD_ec2"
    propagate_at_launch = true
  }
}

#------------------------------ Auto Scaling Policies and Cloud Watch Alarm ----------------------------------

# Auto-Scaling Policy for Scale Up
resource "aws_autoscaling_policy" "ag-scaleup-cpu-policy" {
    name = "ag-scaleup-cpu-policy"
    autoscaling_group_name = aws_autoscaling_group.ag_ec2_instance.name
    adjustment_type = "ChangeInCapacity"
    scaling_adjustment = "1"
    cooldown = "30"
    policy_type = "SimpleScaling"
}

#Cloud Watch alarm for Scale Up
resource "aws_cloudwatch_metric_alarm" "cloudWatch-scaleup-cpu-alarm" {
    alarm_name = "cloudWatch-scaleup-cpu-alarm"
    alarm_description = "Scale up when CPU usage > 70%"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "1"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "60"
    statistic = "Average"
    threshold = "7"
    dimensions = {
      "AutoScalingGroupName" = aws_autoscaling_group.ag_ec2_instance.name
    }
    actions_enabled = true
    alarm_actions = [aws_autoscaling_policy.ag-scaleup-cpu-policy.arn]
}

# Auto-Scaling Policy for Scale Down
resource "aws_autoscaling_policy" "ag-scaledown-cpu-policy" {
    name = "ag-scaledown-cpu-policy"
    autoscaling_group_name = aws_autoscaling_group.ag_ec2_instance.name
    adjustment_type = "ChangeInCapacity"
    scaling_adjustment = "-1"
    cooldown = "30"
    policy_type = "SimpleScaling"
}

#Cloud Watch alarm for Scale Down
resource "aws_cloudwatch_metric_alarm" "cloudWatch-scaledown-cpu-alarm" {
    alarm_name = "cloudWatch-scaledown-cpu-alarm"
    alarm_description = "Scale up when CPU usage < 40%"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "1"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "60"
    statistic = "Average"
    threshold = "4"
    dimensions = {
      "AutoScalingGroupName" = aws_autoscaling_group.ag_ec2_instance.name
    }
    actions_enabled = true
    alarm_actions = [aws_autoscaling_policy.ag-scaledown-cpu-policy.arn]
}

#---------------------------------- RDS --------------------------------------


#Creating an AWS instance
resource "aws_db_instance" "rds_instance" {
  allocated_storage    = var.storage_rds
  engine               = var.rds_engine
  engine_version       = var.rds_engine_version
  instance_class       = var.rds_instance_class
  multi_az             = false
  name                 = var.rds_instance_name
  username             = var.db_master_username
  password             = var.db_master_password
  publicly_accessible  = var.publicly_accessible
  db_subnet_group_name = aws_db_subnet_group.rds_db_subnet_grp.name
  vpc_security_group_ids = [aws_security_group.database_sec_grp.id]
  skip_final_snapshot  = true
}
