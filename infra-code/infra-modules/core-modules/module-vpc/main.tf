locals {
    vpc_cidr = var.vpc_cidr

    private_route_cidrs =  var.private_route_cidrs
    public_route_cidrs =  var.public_route_cidrs
    public_subnets_cidrs =  var.public_subnets_cidrs
    private_subnets_cidrs =  var.private_subnets_cidrs
    public_subnets_available_zones =  var.public_subnets_available_zones
    private_subnets_available_zones =  var.private_subnets_available_zones
    public_route_tables = var.public_route_tables
    private_route_tables = var.private_route_tables


    tags = var.default_tags
}



#################################
# VPC 
#################################
resource "aws_vpc" "app_vpc" {
  cidr_block       = local.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = merge( local.tags , {
    Name = "app_vpc"
  })
}

#################################
# Internet gateway
#################################
resource "aws_internet_gateway" "app_internet_gateway" {
  vpc_id = aws_vpc.app_vpc.id

  tags = merge( local.tags , {
    Name = "app_internet_gateway"
  })
}

#################################
# Public Route table
#################################
resource "aws_route_table" "public_route_tables" {
    for_each = toset( [ for i, v in local.public_route_tables : tostring(tonumber(i)+1) ] )
    vpc_id = aws_vpc.app_vpc.id

    tags = merge( local.tags , {
        Name = "public_route_table_${each.value}"
    })
}

#################################
# Public Routes
#################################
resource "aws_route" "public_routes" {
    for_each = { for i, value in local.public_route_cidrs: (tonumber(i)+1) => value }
    route_table_id            = aws_route_table.public_route_tables[each.key].id
    destination_cidr_block    = each.value
    gateway_id                = aws_internet_gateway.app_internet_gateway.id
    depends_on                = [aws_route_table.public_route_tables]

}

# #################################
# # Public Subnets
# #################################
resource "aws_subnet" "public_subnets" {
    for_each = { for i, value in local.public_subnets_cidrs: (tonumber(i)+1) => value }
    vpc_id     = aws_vpc.app_vpc.id
    cidr_block = each.value
    availability_zone = local.public_subnets_available_zones[tonumber(each.key)-1]
    map_public_ip_on_launch = true


    tags = merge( local.tags , {
        Name = "public_subnet_${each.key}"
    })
}

resource "aws_route_table_association" "public_subnets_route_table_assoc" {
    for_each = { for i, value in local.public_subnets_cidrs: (tonumber(i)+1) => value }
    subnet_id      = aws_subnet.public_subnets[each.key].id
    route_table_id = aws_route_table.public_route_tables["1"].id
    #We are creating only 1 public route table with 2 public subnets so each public subnets is assoc with the same and only route table 
    #route_table_id = aws_route_table.public_route_tables[(tonumber(each.key)-1)].id
}


# #################################
# # Elastic Ip Adresses
# #################################
resource "aws_eip" "elastic_ip_address" {
    for_each = { for i, value in local.public_subnets_cidrs: (tonumber(i)+1) => value }
    domain   = "vpc"
    tags = merge( local.tags , {
        Name = "elastic_ip_${each.key}"
    })
}


# #################################
# # Nat gateways
# #################################
resource "aws_nat_gateway" "app_nat_gateway" {
    for_each = { for i, value in local.public_subnets_cidrs: (tonumber(i)+1) => value }
    allocation_id = aws_eip.elastic_ip_address[each.key].id
    subnet_id     = aws_subnet.public_subnets[each.key].id

    tags = merge( local.tags , {
        Name = "nat_gateway_${each.key}"
    })

  depends_on = [aws_internet_gateway.app_internet_gateway]
}

# #################################
# # Private route tables
# #################################
resource "aws_route_table" "private_route_tables" {
    for_each = { for i, value in local.private_route_tables: (tonumber(i)+1) => value }
    vpc_id = aws_vpc.app_vpc.id

    tags = merge( local.tags , {
        Name = "private_route_table_${each.value}"
    })
}


# #################################
# # Private routes
# #################################
resource "aws_route" "private_routes" {
    for_each = { for i, value in local.private_route_cidrs: (tonumber(i)+1) => value }
    route_table_id            = aws_route_table.private_route_tables[each.key].id
    destination_cidr_block    = each.value
    nat_gateway_id            = aws_nat_gateway.app_nat_gateway[each.key].id
    depends_on                = [aws_route_table.private_route_tables]
}

# #################################
# # Private Subnets
# #################################
resource "aws_subnet" "private_subnets" {
    for_each = { for i, value in local.private_subnets_cidrs: (tonumber(i)+1) => value }
    vpc_id     = aws_vpc.app_vpc.id
    cidr_block = each.value
    availability_zone = local.private_subnets_available_zones[(tonumber(each.key)-1)]
    map_public_ip_on_launch = true

    tags = merge( local.tags , {
        Name = "private_subnet_${each.key}"
    })
}

resource "aws_route_table_association" "private_subnets_route_table_assoc" {
    for_each = { for i, value in local.private_subnets_cidrs: (tonumber(i)+1) => value }
    subnet_id      = aws_subnet.private_subnets[each.key].id
    route_table_id = aws_route_table.private_route_tables[each.key].id
}

