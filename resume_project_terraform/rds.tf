resource "aws_db_subnet_group" "status-sn" {
    name = "status-db_subnet-group"
    
    subnet_ids = aws_subnet.status-private_subnets[*].id

    tags = {
      Name = "status-db-sn-group"
    }

    
}


resource "aws_db_instance" "status-RDS" {
    db_name = "myDB"
    identifier = "status-db"
    instance_class = var.db_instance_class
    engine = "postgres"
    engine_version = "15.16"
    username = var.db_username
    password = var.db_password
    port = 5432
    allocated_storage = 20
    storage_type = "gp2"
    skip_final_snapshot = true

    multi_az = false

    db_subnet_group_name = aws_db_subnet_group.status-sn.name
    vpc_security_group_ids = [aws_security_group.status-rds.id]

    

    tags = {
      Name = "status-db"
    }

}