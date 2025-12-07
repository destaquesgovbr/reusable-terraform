output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.main.id
}

output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.main.name
}

output "network_self_link" {
  description = "The self_link of the VPC network"
  value       = google_compute_network.main.self_link
}

output "subnetwork_id" {
  description = "The ID of the subnet"
  value       = google_compute_subnetwork.main.id
}

output "subnetwork_name" {
  description = "The name of the subnet"
  value       = google_compute_subnetwork.main.name
}

output "subnetwork_self_link" {
  description = "The self_link of the subnet"
  value       = google_compute_subnetwork.main.self_link
}

output "router_name" {
  description = "The name of the Cloud Router"
  value       = google_compute_router.main.name
}

output "nat_name" {
  description = "The name of the Cloud NAT"
  value       = google_compute_router_nat.main.name
}
