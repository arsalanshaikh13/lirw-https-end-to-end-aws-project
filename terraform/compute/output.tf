output "tg_arn" {
  value = module.alb.tg_arn
}
output "internal_tg_arn" {
  value = module.alb.internal_tg_arn
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "alb_zone_id" {
  value = module.alb.alb_zone_id
}
output "internal_alb_dns_name" {
  value = module.alb.internal_alb_dns_name
}
output "public_alb_arn" {
  value = module.alb.public_alb_arn
}