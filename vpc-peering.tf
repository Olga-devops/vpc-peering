module "vpc-virginia" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.53.0"
  
  name = "terraform-vpc-virginia"
  
  cidr = "16.0.0.0/16"

  azs            = ["us-east-1a", "us-east-1b"]
  public_subnets = ["16.0.1.0/24", "16.0.2.0/24"]
  private_subnets = ["16.0.101.0/24", "16.0.102.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true
   providers = {
    aws = "aws.virginia"
  }
}

module "vpc-ohio" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.53.0"

  name = "terraform-vpc-ohio"
  cidr = "198.0.0.0/16"

  azs            = ["us-east-2a", "us-east-2b"]
  public_subnets = ["198.0.1.0/24", "198.0.2.0/24"]
  private_subnets = ["198.0.101.0/24", "198.0.102.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true
  providers = {
    aws = "aws.ohio"
  }
}

resource "aws_vpc_peering_connection" "pc" {
  peer_vpc_id = "${module.vpc-virginia.vpc_id}"
  vpc_id      = "${module.vpc-ohio.vpc_id}"
  auto_accept = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags = {
    Name = "vpc-ohio to vpc-virginia VPC peering"
  }
}

resource "aws_route" "vpc-peering-route-virginia" {
  count                     = 2
  route_table_id            = "${module.vpc-virginia.public_route_table_ids[0]}"
  destination_cidr_block    = "${module.vpc-ohio.public_subnets_cidr_blocks[count.index]}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.pc.id}"
}

resource "aws_route" "vpc-peering-route-ohio" {
  count                     = 2
  route_table_id            = "${module.vpc-ohio.public_route_table_ids[0]}"
  destination_cidr_block    = "${module.vpc-virginia.public_subnets_cidr_blocks[count.index]}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.pc.id}"
}