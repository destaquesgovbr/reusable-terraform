output "instance_name" {
  description = "Name of the sandbox VM"
  value       = google_compute_instance.sandbox.name
}

output "instance_id" {
  description = "ID of the sandbox VM"
  value       = google_compute_instance.sandbox.id
}

output "instance_self_link" {
  description = "Self-link of the sandbox VM"
  value       = google_compute_instance.sandbox.self_link
}

output "zone" {
  description = "Zone where the VM is located"
  value       = var.zone
}

output "internal_ip" {
  description = "Internal IP address of the VM"
  value       = google_compute_instance.sandbox.network_interface[0].network_ip
}

output "data_disk_name" {
  description = "Name of the persistent data disk"
  value       = google_compute_disk.data.name
}

output "data_disk_id" {
  description = "ID of the persistent data disk"
  value       = google_compute_disk.data.id
}

output "ssh_command" {
  description = "SSH command to connect via IAP"
  value       = "gcloud compute ssh ${google_compute_instance.sandbox.name} --zone=${var.zone} --tunnel-through-iap"
}
