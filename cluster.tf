resource "aws_security_group" "allow_rabbitmq" {
  name        = "rabbitmq-${var.ENV}"
  description = "rabbitmq-${var.ENV}"
  vpc_id      = data.terraform_remote_state.vpc.outputs.VPC_ID

  ingress {
    description = "TLS from VPC"
    from_port   = var.RABBITMQ_PORT
    to_port     = var.RABBITMQ_PORT
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.vpc.outputs.VPC_CIDR]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.vpc.outputs.VPC_CIDR, "172.31.15.197/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "rabbitmq-${var.ENV}"
  }
}

//resource "aws_mq_broker" "rabbitmq" {
//  broker_name = "roboshop-${var.ENV}"
//
//  engine_type        = "RabbitMQ"
//  engine_version     = var.RABBITMQ_ENGINE_VERSION
//  host_instance_type = var.RABBITMQ_INSTANCE_TYPE
//  security_groups    = [aws_security_group.allow_rabbitmq.id]
//  subnet_ids         = [data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNET_IDS[0]]
//
//  user {
//    username = jsondecode(data.aws_secretsmanager_secret_version.secrets.secret_string)["RABBITMQ_USERNAME"]
//    password = jsondecode(data.aws_secretsmanager_secret_version.secrets.secret_string)["RABBITMQ_PASSWORD"]
//  }
//}

resource "aws_spot_instance_request" "rabbitmq" {
  //ami                    = data.aws_ami.ami.id
  ami                    = "ami-0bb6af715826253bf"
  instance_type          = "t3.micro"
  wait_for_fulfillment   = true
  vpc_security_group_ids = [aws_security_group.allow_rabbitmq.id]
  subnet_id              = data.terraform_remote_state.vpc.outputs.PRIVATE_SUBNET_IDS[0]

  tags = {
    Name = "rabbitmq-${var.ENV}"
  }
}

resource "null_resource" "app-deploy" {
  provisioner "remote-exec" {
    connection {
      host     = aws_spot_instance_request.rabbitmq.private_ip
      user     = jsondecode(data.aws_secretsmanager_secret_version.secrets.secret_string)["SSH_USERNAME"]
      password = jsondecode(data.aws_secretsmanager_secret_version.secrets.secret_string)["SSH_PASSWORD"]
    }
    inline = [
      "sudo labauto ansible",
      "ansible-pull -U https://github.com/raghudevopsb63/ansible roboshop.yml  -e role_name=rabbitmq -e HOST=localhost  -e ENV=${var.ENV}"
    ]
  }
}