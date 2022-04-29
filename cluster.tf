resource "aws_security_group" "allow_rabbitmq" {
  name        = "roboshop-rabbitmq-${var.ENV}"
  description = "roboshop-rabbitmq-${var.ENV}"
  vpc_id      = data.terraform_remote_state.vpc.outputs.VPC_ID

  ingress {
    description = "TLS from VPC"
    from_port   = 5672
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.vpc.outputs.VPC_CIDR]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "roboshop-rabbitmq-${var.ENV}"
  }
}

resource "aws_mq_broker" "rabbitmq" {
  broker_name = "roboshop-${var.ENV}"

  configuration {
    id       = aws_mq_configuration.config-main.id
    revision = aws_mq_configuration.config-main.latest_revision
  }

  engine_type        = "RabbitMQ"
  engine_version     = "3.9.13"
  host_instance_type = "mq.t2.micro"
  security_groups    = [aws_security_group.allow_rabbitmq.id]

  user {
    username = "roboshop"
    password = "RoboShop1234"
  }
}

resource "aws_mq_configuration" "config-main" {
  description             = "roboshop-${var.ENV}"
  name                    = "roboshop-${var.ENV}"
  engine_type             = "RabbitMQ"
  engine_version          = "3.9.13"
  data                    = ""
  authentication_strategy = "simple"
}


