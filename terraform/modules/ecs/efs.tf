resource "aws_efs_file_system" "this" {
  encrypted = true
  tags      = { Name = var.name_prefix }
}

resource "aws_efs_mount_target" "this" {
  for_each = toset(var.subnets)

  file_system_id  = aws_efs_file_system.this.id
  security_groups = [var.security_group_efs]
  subnet_id       = each.value
}

resource "aws_efs_access_point" "this" {
  file_system_id = aws_efs_file_system.this.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/${var.name_prefix}"

    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 770
    }
  }
}
