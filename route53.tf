resource "aws_route53_record" "record" {
  zone_id = data.terraform_remote_state.vpc.outputs.HOSTEDZONE_PRIVATE_ID
  name    = "rabbitmq-${var.ENV}.${data.terraform_remote_state.vpc.outputs.HOSTEDZONE_PRIVATE_ZONE}"
  type    = "A"
  ttl     = "300"
  records = [aws_spot_instance_request.rabbitmq.private_ip]
}
