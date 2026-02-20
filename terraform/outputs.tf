# ── VPC ───────────────────────────────────────────────────────────────────────
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# ── Frontend Subnets ─────────────────────────────────────────────────────────
output "frontend_subnet_ids" {
  description = "IDs of the public (frontend) subnets"
  value       = [aws_subnet.frontend_a.id, aws_subnet.frontend_b.id]
}

# ── Containerization Subnets ─────────────────────────────────────────────────
output "container_subnet_ids" {
  description = "IDs of the private (containerization) subnets"
  value       = [aws_subnet.container_a.id, aws_subnet.container_b.id]
}

# ── Backend Subnets ──────────────────────────────────────────────────────────
output "backend_subnet_ids" {
  description = "IDs of the private (backend) subnets"
  value       = [aws_subnet.backend_a.id, aws_subnet.backend_b.id]
}

# ── Gateways ─────────────────────────────────────────────────────────────────
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.igw.id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways (AZ-A, AZ-B)"
  value       = [aws_nat_gateway.nat_a.id, aws_nat_gateway.nat_b.id]
}

# ── Security Groups ──────────────────────────────────────────────────────────
output "sg_frontend_id" {
  description = "Security group ID for the frontend tier"
  value       = aws_security_group.frontend.id
}

output "sg_container_id" {
  description = "Security group ID for the containerization tier"
  value       = aws_security_group.container.id
}

output "sg_backend_id" {
  description = "Security group ID for the backend tier"
  value       = aws_security_group.backend.id
}
