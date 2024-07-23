resource "aws_db_instance" "eks_rds_db" {
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7.44"
    name                   = "usermgmtdb"
  identifier             = "usermgmtdb"
  username               = "dbadmin"
  password               = "dbpassword11"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.eks-rds-db-securitygroup.id]
  db_subnet_group_name   = aws_db_subnet_group.eks-rds-db-subnetgroup.name
  publicly_accessible    = true

}