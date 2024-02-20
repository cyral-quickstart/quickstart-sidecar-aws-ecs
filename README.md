# quickstart-sidecar-aws-ecs

## Deploy a single container sidecar on AWS ECS

This guide explains how to deploy a basic sidecar on AWS using
the ECS service. This example provides only the necessary configuration to
deploy a sidecar container. For a more complete example, please see the
[Cyral DIY Deployment](https://cyral.com/docs/sidecars/deployment/#custom-deployment-diy)
documentation.

By following the steps of this guide, you will deploy a sidecar container using
a Fargate instance into an ECS cluster. You'll be able to configure the sidecar
for specific data repositories and control the infrastructure in a way that best
suits your needs.

> In case you want to deploy a sidecar using AWS EC2 instead, please see
> the [Cyral sidecar module for AWS EC2](https://github.com/cyralinc/terraform-aws-sidecar-ec2).

## Usage

1. From your control plane (https://_tenant_.app.cyral.com) create a new sidecar and select Custom as the deployment type.
1. Save the infromation for the steps below.
1. Clone this repository and go to the `sidecar_ecs` directory.
1. Create a sidecar_values.tfvars file in with the following content:

    ```hcl
    # The following values are provided from the `Generate Deployment Parameters`
    # button from the sidecar deployment tab:
    sidecar_id = "<sidecar id>"
    control_plane = "<tenant>.app.cyral.com"
    client_id = "<client id>"
    client_secret = "<client secret>"

    sidecar_version = "v4.10.0" # Use the version shown in the control plane

    # The list of ports you want to expose on the sidecar
    sidecar_ports = [ 5432 ]

    # provide the VPC you want the sidecar to reside in
    vpc_id = "vpc-xxxxxx"
    subnet_ids = [ "subnet-123", "subnet-456" ]
    ```

1. Run `terraform init`
1. Run `terraform apply -var-file=sidecar_values.tfvars`

After a few minutes you'll see your sidecar instance in the control plane.

## Additional Configuration

There are additional options you can configure in the `sidecar_values.tfvars` that are defined in the `variables_*.tf` files.
