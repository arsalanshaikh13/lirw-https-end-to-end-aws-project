
resource "aws_db_subnet_group" "db-subnet" {
  name       = var.db_sub_name
  subnet_ids = [var.pri_sub_7a_id, var.pri_sub_8b_id] # Replace with your private subnet IDs
}

resource "aws_db_instance" "lirw-database" {
  identifier              = "lirw-dev-db"
  engine                  = "mysql"
  engine_version          = "8.0.42"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  username                = var.db_username
  password                = var.db_password
  # db_name                 = var.db_name
  multi_az                = false
  storage_type            = "standard"
  storage_encrypted       = false
  publicly_accessible     = false
  skip_final_snapshot     = true
  backup_retention_period = 0

  vpc_security_group_ids = [var.db_sg_id] # Replace with your desired security group ID

  db_subnet_group_name = aws_db_subnet_group.db-subnet.name

  tags = {
    Name = "appdb"
  }
}