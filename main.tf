provider "aws" {
  region = "ap-northeast-1"
}

# ローカル変数
# EC2インスタンスへの接続元グローバルIPアドレスをコマンドライン入力から受け取る
variable "myip" {
  type = string
  description = "Check-> https://www.whatismyip.com/"
}


##########################################
# VPC
##########################################
resource "aws_vpc" "rds_test_vpc" {
    cidr_block = "10.0.0.0/21"
    tags = {
      Name = "rds_test_vpc"
    }
}


##########################################
# サブネット（パブリック）
##########################################
# パブリックサブネット
# EC2配置用
resource "aws_subnet" "rds_test_public_subnet_1" {
  vpc_id            = aws_vpc.rds_test_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-northeast-1a"
  tags = {
    Name = "rds_test_public_subnet_1"
  }
}
# とりあえず置いたやつ1
resource "aws_subnet" "rds_test_public_subnet_2" {
  vpc_id            = aws_vpc.rds_test_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1c"
  tags = {
    Name = "rds_test_public_subnet_2"
  }
}
# とりあえず置いたやつ2
resource "aws_subnet" "rds_test_public_subnet_3" {
  vpc_id            = aws_vpc.rds_test_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-1d"
  tags = {
    Name = "rds_test_public_subnet_3"
  }
}

# プライベートサブネット
# Aurora(プライマリ)配置用
resource "aws_subnet" "rds_test_private_subnet_1" {
  vpc_id            = aws_vpc.rds_test_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-1a"
  tags = {
    Name = "rds_test_private_subnet_1"
  }
}
# Aurora(レプリカ)配置用1
resource "aws_subnet" "rds_test_private_subnet_2" {
  vpc_id            = aws_vpc.rds_test_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-northeast-1c"
  tags = {
    Name = "rds_test_private_subnet_2"
  }
}
# Aurora(レプリカ)配置用2
resource "aws_subnet" "rds_test_private_subnet_3" {
  vpc_id            = aws_vpc.rds_test_vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "ap-northeast-1d"
  tags = {
    Name = "rds_test_private_subnet_3"
  }
}



##########################################
# サブネットグループ
##########################################
# Auroraのプライマリ、レプリカ1、 レプリカ2を配置するサブネットグループ
resource "aws_db_subnet_group" "rds_test_db_subnet_group" {
    name       = "rds_test_db_subnet_group"
    subnet_ids = [
        aws_subnet.rds_test_private_subnet_1.id,
        aws_subnet.rds_test_private_subnet_2.id,
        aws_subnet.rds_test_private_subnet_3.id
    ]
    tags = {
        Name = "rds_test_db_subnet_group"
    }
}



##########################################
# インターネットゲートウェイ
##########################################
resource "aws_internet_gateway" "rds_test_igw" {
    vpc_id = aws_vpc.rds_test_vpc.id
    tags = {
      Name = "rds_test_igw"
    }
}


##########################################
# ルートテーブルとサブネットへの関連付け
##########################################
# パブリックなサブネットのルートテーブル
resource "aws_route_table" "rds_test_public_rtb" {
    vpc_id = aws_vpc.rds_test_vpc.id
    route  {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.rds_test_igw.id
    }
    tags = {
      Name = "rds_test_public_rtb"
    }
}
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id = aws_subnet.rds_test_public_subnet_1.id
  route_table_id = aws_route_table.rds_test_public_rtb.id
}

# プライベートサブネットのルートテーブル（Auroraプライマリ）
resource "aws_route_table" "rds_test_private_rtb_1" {
    vpc_id = aws_vpc.rds_test_vpc.id
    tags = {
      Name = "rds_test_private_rtb_1"
    }
}
resource "aws_route_table_association" "private_subnet_1_association" {
  subnet_id = aws_subnet.rds_test_private_subnet_1.id
  route_table_id = aws_route_table.rds_test_private_rtb_1.id
}
# プライベートサブネットのルートテーブル（Auroraレプリカ1）
resource "aws_route_table" "rds_test_private_rtb_2" {
    vpc_id = aws_vpc.rds_test_vpc.id
    tags = {
      Name = "rds_test_private_rtb_2"
    }
}
resource "aws_route_table_association" "private_subnet_2_association" {
  subnet_id = aws_subnet.rds_test_private_subnet_2.id
  route_table_id = aws_route_table.rds_test_private_rtb_2.id
}
# プライベートサブネットのルートテーブル（Auroraレプリカ2）
resource "aws_route_table" "rds_test_private_rtb_3" {
    vpc_id = aws_vpc.rds_test_vpc.id
    tags = {
      Name = "rds_test_private_rtb_3"
    }
}
resource "aws_route_table_association" "private_subnet_3_association" {
  subnet_id = aws_subnet.rds_test_private_subnet_3.id
  route_table_id = aws_route_table.rds_test_private_rtb_3.id
}


##########################################
# EC2インスタンス
##########################################
resource "aws_instance" "rds_test_public_ec2" {
    ami = "ami-094dc5cf74289dfbc"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.rds_test_public_subnet_1.id
    associate_public_ip_address = true
    vpc_security_group_ids = [ aws_security_group.rds_test_public_ec2_sg.id ]

    iam_instance_profile = aws_iam_instance_profile.test_rds_instance_profile.name

    key_name = "test-keypair-2"
    tags = {
      Name = "rds_test_public_ec2"
    }
}

##########################################
# ElasticIP
##########################################
resource "aws_eip" "rds_test_public_eip" {
  domain = "vpc"
}
resource "aws_eip_association" "rds_test_public_eip_association" {
  instance_id   = aws_instance.rds_test_public_ec2.id
  allocation_id = aws_eip.rds_test_public_eip.id
}

##########################################
# セキュリティグループ
##########################################
# EC2用
resource "aws_security_group" "rds_test_public_ec2_sg" {
    vpc_id = aws_vpc.rds_test_vpc.id
    name = "rds_test_public_ec2_sg"
    ingress {
        description = "Allow ssh traffic from my IP"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [ "${var.myip}/32" ]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Aurora(プライマリ)用
resource "aws_security_group" "rds_test_aurora_sg_1" {
    vpc_id = aws_vpc.rds_test_vpc.id
    name = "rds_test_aurora_sg_1"
    ingress {
        description = "Allow traffic from EC2"
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [ aws_security_group.rds_test_public_ec2_sg.id ]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}



##########################################
# RDS
##########################################
# Auroraクラスター
resource "aws_rds_cluster" "my_database" {
  cluster_identifier        = "my-database"
  engine                    = "aurora-mysql"
  engine_version            = "8.0.mysql_aurora.3.07.1"
  engine_mode               = "provisioned"
  database_name             = "mydb"

  master_username           = "admin"
  master_password           = "password"

  db_subnet_group_name      = aws_db_subnet_group.rds_test_db_subnet_group.name
  vpc_security_group_ids    = [aws_security_group.rds_test_aurora_sg_1.id]
  port                      = 3306
  enable_http_endpoint      = false

  skip_final_snapshot       = true
  apply_immediately         = true
}

# Auroraインスタンス（プライマリ）
resource "aws_rds_cluster_instance" "my_database_instance_primary" {
  count                = 1
  identifier           = "my-database-instance-${count.index}"
  cluster_identifier   = aws_rds_cluster.my_database.id

  instance_class       = "db.t3.medium"
  engine               = aws_rds_cluster.my_database.engine
  engine_version       = aws_rds_cluster.my_database.engine_version

  publicly_accessible  = false
}
# Auroraインスタンス（レプリカ1）
resource "aws_rds_cluster_instance" "my_database_instance_replica" {
  count                = 1
  identifier           = "my-database-instance-replica-${count.index}"
  cluster_identifier   = aws_rds_cluster.my_database.id

  instance_class       = "db.t3.medium"
  engine               = aws_rds_cluster.my_database.engine
  engine_version       = aws_rds_cluster.my_database.engine_version

  depends_on = [ aws_rds_cluster_instance.my_database_instance_primary ]

  publicly_accessible  = false
}

##########################################
# Auto Scalingポリシー
##########################################
resource "aws_appautoscaling_target" "replicas" {
  service_namespace  = "rds"
  resource_id        = "cluster:${aws_rds_cluster.my_database.cluster_identifier}"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  min_capacity       = 1
  max_capacity       = 2
}

resource "aws_appautoscaling_policy" "my_auto_scaling_policy" {
  name               = "auto-scaling-1"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.replicas.service_namespace
  resource_id        = aws_appautoscaling_target.replicas.resource_id
  scalable_dimension = aws_appautoscaling_target.replicas.scalable_dimension

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "RDSReaderAverageCPUUtilization"
    }

    target_value       = 1
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }

  depends_on = [ aws_appautoscaling_target.replicas ]
}

##########################################
# IAMロール
##########################################
# RDSへのアクセス権限を持つIAMロールを作成
data "aws_iam_policy" "rds_full_access" {
  arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

resource "aws_iam_role" "test_rds_role" {
  name = "test-rds-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "test_rds_role_policy_attachment" {
  policy_arn = data.aws_iam_policy.rds_full_access.arn
  role       = aws_iam_role.test_rds_role.name
}

resource "aws_iam_instance_profile" "test_rds_instance_profile" {
  name = "test-rds-instance-profile"
  role = aws_iam_role.test_rds_role.name
}