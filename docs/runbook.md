Pirep Runbook
=============

## Prerequisites

* Terraform
* AWS CLI tool
* [AWS Session Manager Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)

## Architecture Overview

Pirep is hosted on AWS, primarily through ECS Fargate. AWS services are use sparingly with the intention to minimize monthly costs. A rough architecture diagram is as follows:

```
       +-----------------+               +---------+
       | Public Internet | ---- DNS ---- | Route53 |
       +-----------------+               +---------+
               |
               |
          HTTP traffic
               |
               +----------------- Assets ---------------------+
               |                                              |
      Application Requests                                    |
               |                                              |
   +--------------------------+                         +------------+
   |      Load balancer       | --- Uncached Assets --- | CloudFront |
   | (HTTP -> HTTPS redirect) |                         +------------+
   +--------------------------+                               |
               |                                              |
               |                                 Cached/static assets & map tiles
        +--------------+                                      |
        | Target Group |                                      |
        +--------------+                                   +----+
               |                                           | S3 |
               |                                           +----+
        +-------------+        +-------------+
        | ECS Fargate |        | ECS Fargate |
        +-------------+        +-------------+
               |                      |
               |                      |
         +-----------+         +------------+
         | Web Tasks |         | Jobs Tasks |
         +-----------+         +------------+
               |                      |
               |                      |
               +----------+-----------+
                          |
                          |
                       +-----+
                       | RDS |
                       +-----+
```

## Initial Setup / Disaster Recovery

If a new environment needs to be set up or the existing production environment needs to be re-created the following procedure should be used:

1. Create an SSM parameter named `DOCKER_HUB_CREDENTIALS` with Docker Hub credentials of the following form: `{"username": "USERNAME", "password": "PASSWORD"}`
  * This is necessary because Docker Hub rate limits anonymous pulls of public images and Codebuild instances will use shared IPs which are likely hitting that rate limit
2. `cd terraform/environments/production` and `terraform apply`
  * Note: If restoring from a database backup the backup snapshot should be set in the RDS Terraform resource before applying.
3. `rails deploy` to deploy the app
  * The app should be running enough such that the health check endpoint returns 200s. If it does not containers will continually be killed making it impossible to continue with the rest of this process.
4. Connect to a container via `rails ssh` and run the following to initialize the database (skip this if using a database backup)
  1. `rails db:create`
  2. `rails db:schema:load`
  3. `rails db:seed` (note the default username and password)
  4. `rails c` then `EcsTaskRunnerJob.perform_now('pirep-production-importer')`
    * This will start an importer task to download airport data, diagrams, and charts. This will take many hours to complete. Progress can be monitored in CloudWatch.

## Deployment

A blue/green deployment process is used through AWS Codepipeline/Codedeploy. A small deploy script is written which starts and then monitors this process. There are four stages in the pipeline:

1. Codepipeline pulls the source code from GitHub and passes it on to CodeBuild
2. CodeBuild will build a new image and push it to ECR
3. A separate CodeBuild project then starts a standalone ECS task to run any database migrations
4. CodeDeploy handles deploying the new image to the ECS Services and waits five minutes after deployment before terminating the original tasks

To start a deploy first push the changes to GitHub. Then:

If deploying `master`:
```
rails deploy
```

If deploying another branch:
```
rails deploy -- --branch=[branch name]
```

Ctrl+C will cancel the deployment and initial a rollback if on the CodeDeploy step. The ECS console is the first place to check in the event of a stalled or failed deployment where tasks could not start. Sentry will likely have a stacktrace as well.

## SSH Access

SSH access is done through ECS Exec. It isn't true SSH, but rather uses the AWS Session Manager Plugin to open a command line interface with an ECS task directly. This is done with:

```
rails ssh
```

A prompt will ask for which container to access. The `jobs` containers are preferred to avoid any heavy processing from affecting web traffic on the `web` containers.

## Airport Database Importing

Airport data must be updated every cycle to get updated information. There are multiple airport products used in Pirep:

* FAA airport database of all public and private airports in the United States
* FAA airport diagrams
* FAA sectional & terminal charts
* OurAirports Canadian airport database

The `FaaDataCycle` model holds information on which data cycle each of these products are currently on within Pirep. Updating the data cycle is an automated process, but currently must be started manually. It may be fully automated in the future, but only after it has proven reliable to not need manual oversight due to the high potential for dramatically damaging the database.

Due to the heavy amount of processing required to generate new charts, a standalone ECS task with significantly more CPU and memory resources is created for this purpose. This `importer` task is responsible for doing the downloading and processing of all FAA products and inserting them into the database.

1. (Recommended) Do a test run of this locally first with `MasterDataImporter.new(force_update: true).import!`
2. (Recommended) Take an RDS snapshot before
3. `rails ssh`
4. `rails c` then `EcsTaskRunnerJob.perform_now('pirep-production-importer')`

The `EcsTaskRunnerJob` job will start a standalone ECS task which has its command overridden to run `scripts/master_data_importer.rb`. Note that generating map tiles will take 12+ hours even with the increased resources this task has. Progress can be monitored through a combination of CloudWatch logs and running `htop` in the container to ensure the `gdal` process is running and consuming the expected amount of CPU. Finally, this task will update the `FaaDataCycle` with the new data cycle for each product to start using it on the other containers.

## Terraform

Terraform is used for all AWS configuration and lives in this repository under the `terraform/` directory. The structure of this directory is as follows:

```
terraform/
  environments/
    production/
      production.tf  # The top-level Terraform entry point. All Terraform commands should be run from this directory. This file is most configuration for the `project` module below.
  modules/
    project/
      project.tf     # The central module which calls out to other modules and passes values between them.
    [other modules]/ # All other modules are present in this directory. It is roughly structured as one module per AWS service.
```

Running Terraform changes:

```
cd terraform/environments/production
terraform plan
terraform apply
```

Note that an `AWS_PROFILE` value of `personal` is set in the Terraform configuration. Either override this or create a profile with that name in your AWS config.

## Environment Variables / Secrets

There are four places environment variables are configured:

1. Dockerfile
  * The Dockerfile contains a few statically set environment variables to be included in the image, mainly for configuring of the production environment.
2. SecretsManager static secret
  * `terraform/modules/secretsmanager` defines a SecretsManager secret with values outputted from other Terraform resources. This secret is read into the container's environment variables when started.
3. SecretsManager dynamic secret
  * `terraform/modules/secretsmanager` also defines a SecretsManager secret for values not defined in Terraform. These are secret values that are set manually in the AWS console and are also read into the container's environment variables when started.
4. Rails credentials
  * Other secret values are stored in the Rails' encrypted credentials files. These are edited with `rails credentials:edit --environment [test/development/production]`

## Sentry & Skylight

[Sentry](https://sentry.io) is used for error monitoring on the backend and frontend.

[Skylight](https://skylight.io) is used for performance monitoring on the backend.

## Database Backups

Automated RDS snapshot backups are configured. To make manual local database backups use the following rake tasks:

```
rails ssh
rails db:backup
```

```
rails db:download
```

To make a backup of airport photos from S3:

```
rails s3_sync[path/to/destination]
```
