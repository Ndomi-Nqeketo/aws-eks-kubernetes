resource "aws_security_group" "eks_rds_db_sg" {
  name        = "mysql_sg"
  description = "Allow access for RDS Database on Port 3306"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks_rds_db_sg"
  }
}

resource "aws_security_group" "eks-rds-db-securitygroup" {
  description = "Allow access for RDS Database on Port 3306"
  vpc_id      = var.vpc_id
  name        = "eks-rds-db-securitygroup"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "eks-rds-db-securitygroup"
  }
}