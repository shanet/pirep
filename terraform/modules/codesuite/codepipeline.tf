resource "aws_codepipeline" "this" {
  name     = var.name_prefix
  role_arn = var.iam_role_codepipeline_arn

  artifact_store {
    location = aws_s3_bucket.this.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      category         = "Source"
      name             = "source"
      output_artifacts = ["source"]
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"

      configuration = {
        BranchName           = "devops"
        ConnectionArn        = aws_codestarconnections_connection.github.arn
        DetectChanges        = false
        FullRepositoryId     = var.github_repository
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
    }
  }

  stage {
    name = "Build"

    action {
      category         = "Build"
      input_artifacts  = ["source"]
      name             = "image-build"
      output_artifacts = ["build"]
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.image.name
      }
    }
  }

  stage {
    name = "Migrate"

    action {
      category         = "Build"
      input_artifacts  = ["source", "build"]
      name             = "run-migrations"
      output_artifacts = []
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"

      configuration = {
        PrimarySource = "source"
        ProjectName   = aws_codebuild_project.migrations.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      category        = "Deploy"
      input_artifacts = ["build"]
      name            = var.services.jobs.name_prefix
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = "1"

      configuration = {
        ApplicationName                = aws_codedeploy_app.this.name,
        AppSpecTemplateArtifact        = "build"
        AppSpecTemplatePath            = "appspec_jobs.yml"
        DeploymentGroupName            = module.deployment_group_jobs.group.deployment_group_name,
        Image1ArtifactName             = "build"
        Image1ContainerName            = "IMAGE_URI"
        TaskDefinitionTemplateArtifact = "build"
        TaskDefinitionTemplatePath     = "task_definition_jobs.json"
      }
    }

    action {
      category        = "Deploy"
      input_artifacts = ["build"]
      name            = var.services.web.name_prefix
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = "1"

      configuration = {
        ApplicationName                = aws_codedeploy_app.this.name,
        AppSpecTemplateArtifact        = "build"
        AppSpecTemplatePath            = "appspec_web.yml"
        DeploymentGroupName            = module.deployment_group_web.group.deployment_group_name,
        Image1ArtifactName             = "build"
        Image1ContainerName            = "IMAGE_URI"
        TaskDefinitionTemplateArtifact = "build"
        TaskDefinitionTemplatePath     = "task_definition_web.json"
      }
    }
  }
}

resource "aws_codestarconnections_connection" "github" {
  name          = var.name_prefix
  provider_type = "GitHub"
}

resource "aws_s3_bucket" "this" {
  bucket = "${var.name_prefix}-deployment"
}

resource "aws_s3_bucket_acl" "this" {
  acl    = "private"
  bucket = aws_s3_bucket.this.id
}

# Delete old pipeline artifacts so we're not paying for them in S3 in perpetuity
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "delete_old_artifacts"
    status = "Enabled"

    expiration {
      days = 7
    }
  }
}

output "deployment_bucket" {
  value = aws_s3_bucket.this
}
