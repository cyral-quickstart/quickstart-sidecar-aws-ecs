# Advanced networking configurations

It is possible to deploy this sidecar module to different networking configurations to attend different needs.

For testing and evaluation purposes, it is very common that customers will deploy a public sidecar
(public load balancer and public ECS tasks), but this is not a recommended approach for a production
environment. In production, typically customers will deploy an entirely private sidecar (private load 
balancer and private ECS tasks), but sometimes it is necessary to deploy a public load balancer and
keep ECS tasks in a private subnet. It is also common that more than 5 ports are exposed in a
production sidecar requiring special attention to the number of services and tasks that will
be created for that.

See the following sections how to set up the necessary parameters for each of these scenarios.

All resources outlined below are expected to live in the same VPC, meaning that the parameter
`vpc_id` will correspond to the ID of the VPC of all subnets used throughout the deployment 
configuration.

## Opening more than 5 ports

ECS imposes a hard limit of 5 target groups per service and EC2 imposes a hard limit of 50 listeners
per NLB. This means that if you need to use between 6 and 50 ports, the module will
automatically create extra service definitions for each group of up to 5 ports. Use the following
parameters to configure more sidecar ports:

* `sidecar_ports`: the list of ports that will be opened at the load balancer.

If setting `sidecar_ports = [443, 1433, 1521, 3306, 5432, 5439, 9996, 9999, 27017, 27018, 27019, 31010]`
(12 ports), the module will create 3 service definitions to cover the target groups for ports
`[443, 1433, 1521, 3306, 5432]`, `[5439, 9996, 9999, 27017, 27018]` and `[27019, 31010]`. This
means that each service will intantiate at least 1 task with the sidecar container.
If the variable `ecs_service_desired_count` is set to `2` then a total of `6` ECS
tasks will be instantiated, or `6` sidecar *instances* will be running.

## Public load balancer and public ECS tasks

To deploy an entirely public sidecar, use the following parameters:

* `subnets`: provide public subnets in the same VPC. These subnets will be used for both the ECS
instances and the load balancer. All the provided subnets must allow the allocation of public IPs
and have a route to an internet gateway to enable internet access.
* `load_balancer_scheme`: set to `"internet-facing"`.
* `ecs_assign_public_ip` set to `true`.

## Private load balancer and private ECS tasks

To deploy an entirely private sidecar, use the following parameters:

* `subnets`: provide private subnets in the same VPC. These subnets will be used for both the ECS
instances and the load balancer. All the provided subnets must have a route to the internet
through a NAT gateway.
* `load_balancer_scheme`: set to `"internal"` (this is the default value).
* `ecs_assign_public_ip` set to `false` (this is the default value).

## Public load balancer and private ECS tasks

To deploy a public load balancer and private ECS tasks, use the following parameters:

* `subnets`: provide private subnets in the same VPC. These subnets will be used only for the ECS
instances. All the provided subnets must have a route to the internet through a NAT gateway.
* `load_balancer_subnets`: provide public subnets in the same VPC and the same AZs as those in
parameter `subnets`. These subnets will be used only for the load balancer. All the provided 
subnets must allow the allocation of public IPs and have a route to an internet gateway to 
enable internet access. If two private subnets in AZ1 and AZ2 were provided in `subnets`, use
public subnets in the same AZs for this parameter. Failing to provide matching subnets will
cause the target group to not be able to route the traffic to the ECS tasks.
* `load_balancer_scheme`: set to `"internet-facing"`.
* `ecs_assign_public_ip` set to `false` (this is the default value).
