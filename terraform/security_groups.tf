# 1. ALB(로드밸런서) 보안 그룹: 외부에서 80 포트로 접속 허용 (EKS Ingress Controller용)
resource "aws_security_group" "alb_sg" {
  name   = "jpx-alb-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. (참고) ECS 보안 그룹은 삭제 혹은 비활성화 권장
# EKS 노드 보안 그룹은 모듈 내부에서 생성되므로, 별도로 생성하지 않고 module.eks.node_security_group_id를 참조합니다.

# 3. RDS(데이터베이스) 보안 그룹: EKS 노드 및 Bastion에서 오는 트래픽만 허용
resource "aws_security_group" "rds_sg" {
  name   = "jpx-rds-sg"
  vpc_id = module.vpc.vpc_id

  # [수정] EKS Node에서 RDS 접근 허용
  ingress {
    description     = "Allow inbound traffic from EKS nodes to MySQL RDS"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  # Bastion에서 RDS 접근 허용 (기존 유지)
  ingress {
    description     = "Allow inbound traffic from Bastion to MySQL RDS"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}