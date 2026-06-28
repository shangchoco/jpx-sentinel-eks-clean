# ==========================================
# RDS インスタンス設定
# ==========================================
resource "aws_db_instance" "default" {
  allocated_storage     = 20
  db_name               = "jpxdb"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.micro" # AWS無料利用枠の範囲内
  username              = var.db_username
  password              = var.db_password # 本番環境ではAWS Secrets Manager等の利用を推奨
  skip_final_snapshot   = true
  deletion_protection   = true
  # セキュリティ強化のため、パブリックアクセスを無効化
  publicly_accessible = false

  # セキュリティグループおよびサブネットグループの紐付け
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = module.vpc.database_subnet_group_name

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      password,
      username
    ]
  }

  tags = {
    Name = "jpx-db-instance"
  }
}

# ==========================================
# 추가: EKS 클러스터 SG에서 RDS로의 접근 허용
# ==========================================
resource "aws_security_group_rule" "allow_eks_cluster_sg_to_rds" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  security_group_id = aws_security_group.rds_sg.id
  
  # 클러스터 보안 그룹
  source_security_group_id = "sg-0a9f7fde4641b7f3d" 
  
  description       = "Allow inbound traffic from EKS cluster SG to MySQL RDS"
}

# ==========================================
# 추가: EKS 노드 추가 보안 그룹에서 RDS로의 접근 허용
# ==========================================
resource "aws_security_group_rule" "allow_eks_node_sg_to_rds" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  security_group_id = aws_security_group.rds_sg.id
  
  # 노드 추가 보안 그룹
  source_security_group_id = "sg-04b7b120419f8d0e6" 
  
  description       = "Allow inbound traffic from EKS node additional SG to MySQL RDS"
}