resource "aws_db_subnet_group" "eks-rds-db-subnetgroup" {
  description = "EKS RDS DB Subnet Group"
  subnet_ids  = [var.subnet_id_1a, var.subnet_id_1b]

  tags = {
    Name = "eks-rds-db-subnetgroup"
  }
}