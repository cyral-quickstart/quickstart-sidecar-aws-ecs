# quickstart-sidecar-aws-ecs

## Deploy a single container sidecar on AWS ECS

This guide explains how to deploy a single container sidecar on AWS using 
the ECS service. 

By following the steps of this guide, you will deploy a sidecar container using 
a Fargate instance into an ECS cluster. You'll be able to configure the sidecar 
for specific data repositories and control the infrastructure in a way that best 
suits your needs.

In case you want to deploy a sidecar using AWS EC2 instead, please see
the [Cyral sidecar module for AWS EC2](https://github.com/cyralinc/terraform-cyral-sidecar-aws).

## Usage
To deploy the single container sidecar into AWS ECS go to the [sidecar_ecs](./sidecar_ecs/) folder and simply type a `terraform init` followed by a `terraform apply` command. You'll be asked to set the values for the required variables. You can also create a `terraform.tfvars` file to define the variable values. For more information see the [Terraform Input Variables](https://www.terraform.io/language/values/variables) documentation.

If you have any doubt about what values to provide, follow the steps below.

## Configure required providers
Define the required AWS provider version. See the [versions.tf](./sidecar_ecs//versions.tf) file.

## Create a single container sidecar
You can register a single container sidecar and it's credentials 
in the Cyral control plane by using the [cyral_sidecar](https://registry.terraform.io/providers/cyralinc/cyral/latest/docs/resources/sidecar) and [cyral_sidecar_credentials](https://registry.terraform.io/providers/cyralinc/cyral/latest/docs/resources/sidecar_credentials) 
resources of the Cyral Terraform Provider. For more information, please see the 
[Cyral Terraform Provider Documentation](https://registry.terraform.io/providers/cyralinc/cyral/latest/docs). If you already have a sidecar registered, 
you can skip this part.

## Define the sidecar variables
Define the variables that are going to be used to configure the sidecar. See the [variables_sidecar.tf](./sidecar_ecs/variables_sidecar.tf) file.

## Define the ECS variables
Define the variables that are going to be used to configure the ECS resources. See the [variables_ecs.tf](./sidecar_ecs/variables_ecs.tf) file.

## Define the AWS variables
Define the variables of the AWS resources that are going to be used to configure the sidecar infraestructure. See the [variables_aws.tf](./sidecar_ecs/variables_aws.tf) file.

## Configure the ECS resources
Create and configure the resources that will deploy
the sidecar container into the AWS ECS. See the [sidecar_ecs_resources.tf](./sidecar_ecs/sidecar_ecs_resources.tf) file.

### Container Definition Configuration
Define the sidecar container definition configuration. See the [sidecar_container_definition.tf](./sidecar_ecs/sidecar_container_definition.tf) file. This configuration consists of a list of valid task container definition parameters. For a detailed description of what parameters are available, see the [Task Definition Parameters](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html) in the
official AWS Developer Guide.

## Next steps
In this guide, we described how to deploy and configure a single container sidecar into the AWS ECS. 
To learn how to access a repository through the sidecar, see the documentation
on how to [Connect to a repository](https://cyral.com/docs/connect/repo-connect/#connect-to-a-data-repository-with-sso-credentials).