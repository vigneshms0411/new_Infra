locals {
  name = var.project_name
  tags = {
    Project   = local.name
    ManagedBy = "Terraform"
  }
}

# ── VPC ───────────────────────────────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, { Name = "${local.name}-vpc" })
}

# ── Internet Gateway ─────────────────────────────────────────────────────────
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.tags, { Name = "${local.name}-igw" })
}

# ════════════════════════════════════════════════════════════════════════════
# SUBNETS
# ════════════════════════════════════════════════════════════════════════════

# ── Frontend – Public ────────────────────────────────────────────────────────
resource "aws_subnet" "frontend_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.frontend_subnet_a_cidr
  availability_zone       = var.az_a
  map_public_ip_on_launch = true

  tags = merge(local.tags, { Name = "${local.name}-frontend-a", Tier = "frontend" })
}

resource "aws_subnet" "frontend_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.frontend_subnet_b_cidr
  availability_zone       = var.az_b
  map_public_ip_on_launch = true

  tags = merge(local.tags, { Name = "${local.name}-frontend-b", Tier = "frontend" })
}

# ── Containerization – Private ───────────────────────────────────────────────
resource "aws_subnet" "container_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.container_subnet_a_cidr
  availability_zone = var.az_a

  tags = merge(local.tags, { Name = "${local.name}-container-a", Tier = "containerization" })
}

resource "aws_subnet" "container_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.container_subnet_b_cidr
  availability_zone = var.az_b

  tags = merge(local.tags, { Name = "${local.name}-container-b", Tier = "containerization" })
}

# ── Backend – Private ────────────────────────────────────────────────────────
resource "aws_subnet" "backend_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.backend_subnet_a_cidr
  availability_zone = var.az_a

  tags = merge(local.tags, { Name = "${local.name}-backend-a", Tier = "backend" })
}

resource "aws_subnet" "backend_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.backend_subnet_b_cidr
  availability_zone = var.az_b

  tags = merge(local.tags, { Name = "${local.name}-backend-b", Tier = "backend" })
}

# ════════════════════════════════════════════════════════════════════════════
# NAT GATEWAYS  (one per AZ for HA)
# ════════════════════════════════════════════════════════════════════════════
resource "aws_eip" "nat_a" {
  domain = "vpc"
  tags   = merge(local.tags, { Name = "${local.name}-nat-eip-a" })
}

resource "aws_eip" "nat_b" {
  domain = "vpc"
  tags   = merge(local.tags, { Name = "${local.name}-nat-eip-b" })
}

resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.frontend_a.id   # NAT lives in the public subnet

  tags       = merge(local.tags, { Name = "${local.name}-nat-a" })
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.frontend_b.id

  tags       = merge(local.tags, { Name = "${local.name}-nat-b" })
  depends_on = [aws_internet_gateway.igw]
}

# ════════════════════════════════════════════════════════════════════════════
# ROUTE TABLES
# ════════════════════════════════════════════════════════════════════════════

# ── Public route table (Frontend) ────────────────────────────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.tags, { Name = "${local.name}-rt-public" })
}

resource "aws_route_table_association" "frontend_a" {
  subnet_id      = aws_subnet.frontend_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "frontend_b" {
  subnet_id      = aws_subnet.frontend_b.id
  route_table_id = aws_route_table.public.id
}

# ── Private route table – AZ-A (Container + Backend) ────────────────────────
resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = merge(local.tags, { Name = "${local.name}-rt-private-a" })
}

resource "aws_route_table_association" "container_a" {
  subnet_id      = aws_subnet.container_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "backend_a" {
  subnet_id      = aws_subnet.backend_a.id
  route_table_id = aws_route_table.private_a.id
}

# ── Private route table – AZ-B (Container + Backend) ────────────────────────
resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }

  tags = merge(local.tags, { Name = "${local.name}-rt-private-b" })
}

resource "aws_route_table_association" "container_b" {
  subnet_id      = aws_subnet.container_b.id
  route_table_id = aws_route_table.private_b.id
}

resource "aws_route_table_association" "backend_b" {
  subnet_id      = aws_subnet.backend_b.id
  route_table_id = aws_route_table.private_b.id
}

# ════════════════════════════════════════════════════════════════════════════
# SECURITY GROUPS
# ════════════════════════════════════════════════════════════════════════════

# ── Frontend SG ──────────────────────────────────────────────────────────────
# Accepts HTTP/HTTPS from the internet; allows all outbound.
resource "aws_security_group" "frontend" {
  name        = "${local.name}-sg-frontend"
  description = "Allow HTTP/HTTPS inbound from internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name}-sg-frontend" })
}

# ── Containerization SG ──────────────────────────────────────────────────────
# Accepts traffic only from the frontend SG; allows all outbound (via NAT).
resource "aws_security_group" "container" {
  name        = "${local.name}-sg-container"
  description = "Allow inbound from frontend tier only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "App traffic from frontend"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name}-sg-container" })
}

# ── Backend SG ───────────────────────────────────────────────────────────────
# Accepts DB traffic (5432/3306) only from container SG. No inbound from internet.
resource "aws_security_group" "backend" {
  name        = "${local.name}-sg-backend"
  description = "Allow DB inbound from container tier only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from container tier"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.container.id]
  }

  ingress {
    description     = "MySQL/Aurora from container tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.container.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name}-sg-backend" })
}
