variable "name_prefix" {}

resource "aws_ecr_repository" "this" {
  name = var.name_prefix
}

# Only keep the previous five images
resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        action = {
          type = "expire"
        },

        description  = "Keep last 5 images",
        rulePriority = 1,

        selection = {
          countNumber = 5
          countType   = "imageCountMoreThan",
          tagStatus   = "any",
        },
      }
    ]
  })

  #depends_on = [aws_ecr_repository.this]
}

output "repository" {
  value = aws_ecr_repository.this
}
