output "enabled_services" {
  description = "List of enabled API services"
  value       = [for service in google_project_service.services : service.service]
}
