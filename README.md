# Terraform Quickstart

>**Tools**: Bash, Terraform, AWS, Cloudformation, SSH

## Introduction

In this lab, we are going to explore the use of terraform to define infrastructure in the form of code. The idea is that we will define some cloud resources in a configuration file and then a tool will be in charge of creating the resources. If you are not entirely familiar with what Infrastructure as Code (IaC) is, go and read [What is Infrastructure as Code](https://aws.amazon.com/what-is/iac/#:~:text=Infrastructure%20as%20code%20(IaC)%20is,%2C%20database%20connections%2C%20and%20storage), short description from AWS. 

As mentioned, we will use Terraform, which is one of the most widely used tools to do this. Terraform by itself is not too complicated. There are very few concepts that you need to be familiar with and you will certainly get familiar with them in this lab. For this lab we assume you are already familiar with the AWS Console and that you know its most basic services (like S3, EC2, Lambda, etc.)

Let's get started!

## Instructions

First of go through [What is Infrastrcuture as Code with Terraform?](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/infrastructure-as-code) and then install the following tools:
* [Terraform](https://developer.hashicorp.com/terraform/install)
* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

The latter is needed because we will use AWS as our cloud for this lab, but terraform support most cloud providers. For one of the things we need it is to authenticate ourselves with AWS, once you have installed the aws cli, do

```bash
aws configure sso
```
when promted to give a session name, you can type anything (e.g. `factored`); then fill in the other fields using the information you can see in your account information in the AWS Access Portal. 

Afterwards, do

```bash
aws sso login
```
And follow the instructions finish the configuration. Pay special attention to the name of the profile (which you can customize), we will refer to such name later. If you take a couple of session to do the lab, you may need to run `aws sso login --profile [YOUR PROFILE NAME]` to get a new set of credentials.

There are other ways to get your credentials in place, but we believe this to be the best practice. 

### Task 1: The Terraform workflow

Let's start very small, let's create a simple s3 bucket with most of its configuration default. Go to the `./task_1` folder (`cd ./task_1`) and do 

```bash
terraform init
```
Yo always need that to start working with terraform.

Second, go into `./task_1/terraform.tf` and figure out:

1. What piece of the file you need to modify in order to give a name for the bucket. Go to the [AWS S3 Bucket resource documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) for help.
2. What piece of the file you need to change in order to provide the `Owner` tag with your GitHub user name as value. [See provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#default_tags-1)
3. What you need to modify in order to use the profile name you defined when you configured AWS with SSO. [See provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#shared-configuration-and-credentials-files)

Now, run:

```bash
terraform plan
```
so that terraform compares the current infrastructure you have (nothing) with the updates it needs to perform. Inspect the result and make sure it tells you it is only going to create an S3 bucket and that it has taken the expected values for the `Owner` tag and bucket name.

Once that is fine, you can run

```bash
terraform apply
```
and enter `yes` when promted for confirmation.

At this point you should be able to see your S3 bucket in the AWS Console. Notice how a file called `terraform.tfstate` was created and contains information about the infrastructure you just created.

Finally, let's destroy the infrastructure just created to cover the last of the main terraform commands, run

```bash
terraform destroy
```

Upon confirmation from your side, the command should succeed and you will no longer be able to see the S3 bucket in the AWS Console. Moreover, you will see that the contents of `terraform.tfstate` have changed.

There is just one additional command (`terraform validate`), which you can use to verify that the syntax is correct, but it doesn't really tells you that the configuration is correct. 

**Food for thought:**
* How did we tell terraform that we wanted to use the AWS provider?
* What is a resource in terraform?
* How do you think terraform uses the files created/modified during the execution of the commands above?

### Task 2: Setting up a Terraform Backend

From the previous task, you noticed that a file `terraform.tfstate` was created/modified when you run `terraform apply` or `terraform destroy` commands. That file basically allows terraform to keep track of the infrastructure it manipulates. However, this file shouldn't be kept on your own computer. It should be stored and encrypted somewhere that other developers (through `terraform`) can also access to it, enabling collaboration. This is what [terraform backend](https://developer.hashicorp.com/terraform/language/backend) is for. 

For this task, we will basically setup the same infrastructure as in the previous task, but this time we will use terraform backend to keep track of its state. For this we basically need a remote storage, we will use AWS S3. 

However, the backend needs to be an input to our terraform configuration files, so we can't define it in them. We will use AWS Cloudformation to create the backend for terraform, but don't worry, you don't need to learn about cloudformation that much, just know that it is AWS' own solution for Infrastructure as Code and execute the script we prepared for you. Just run `bash ./create_backend.sh [YOUR PROFILE NAME]` and keep track of the name of the stack that is created. You should be able to see a new stack on AWS CloudFormation in the AWS Console.

For this task, on top of what you did for the previous one, you will also need to specify the backend options following the [documentation for the S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3). We have provided you with some basic settings, but you should configure the rest. Read [State Locking](https://developer.hashicorp.com/terraform/language/state/locking) for more information about what it does.

Without further ado go to the `./task_2` folder, modify it how you need to and create the infrastructure using the workflow you learnt in the previous task. Please remember to delete the created resources after you have verified that everything was deployed as expected.

### Task 3: More Terraform concepts

In this task, we will use a few more concepts in terraform that are very useful:
* [Data Sources](https://developer.hashicorp.com/terraform/language/data-sources).
* [Variables](https://developer.hashicorp.com/terraform/language/values/variables).
* [Outputs](https://developer.hashicorp.com/terraform/language/values/outputs).
* [Modules](https://developer.hashicorp.com/terraform/language/modules).

Go and read the links above and then go to `./task_3` to finish up the code to deploy the infrastructure for this task. Our goal this time is to have an EC2 instance with some software preinstalled and be able to connect to it using SSH (to generate one, you could do `ssh-keygen -t rsa -b 4096 -f ~/.ssh/[NAME FOR THE KEY]`). 

**NOTES:**
* When adding the name of the AMI you will use, make sure to use an Ubuntu AMI that is free tier elegible.
* Use the [File Function](https://developer.hashicorp.com/terraform/language/functions/file) to point to the public ssh key that you generated for this. 
* Without modifying the default instance type defined in `./task_3/ec2/variables.tf`, make sure you use a `t2.micro` instance.

Once you are done applying the infrastructure, you should be able to see the public IP of the instance and you could connect to it with `ssh -i ~/.ssh/[NAME FOR THE KEY] ubuntu@ec2-[CREATED IP REPLACING . WITH - ].compute-1.amazonaws.com`.

**Food for thought:**
* How do we choose what we define as a variable?
* How do we choose what we define as an output?
* What would we need to change so that our instance have other software installed when it is created?

### Optional tasks:

* Review [terraform registry](https://developer.hashicorp.com/terraform/language/modules/sources#terraform-registry) to discover a bunch of pre made modules that you can use in your applications, saving yourself a bunch of boilerplate and ensuring best practices. You can think of the modules you will find there as functions in a programming languages. Sometimes you will just find the function you need, while other times you put together a bunch of functions and more primitive instructions (in this case resources), to get to what you need. Look for example at the [S3 Module](https://registry.terraform.io/modules/terraform-aws-modules/ and s3-bucket/aws/latest) [EC2 Module](https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws/latest) modules.

Lab3: Terraform - Vencimiento1 de octubre de 2025 18:00
Min. Dat. Gdes. Vols. de Info.
Deben entregar un código en GitHub que tenga 5 carpetas con código de Terraform que (una asignación por carpeta):

Una instancia de EC2 que tenga Python y Pandas instalado.
Una instancia de EC2 que tenga Python y Polars instalado.
Una instancia de EC2 que tenga Python y DuckDB instalado.
Una instancia de EC2 que tenga Python y Spark instalado.
Una cluster de EMR en el que puedan correr Spark distribuido.
En cada carpeta deben incluir las instrucciones para ejecutar el código y un pantallazo que demuestre que tienen la instalación correcta. Para cada caso deben tener instrucciones para conectarse por SSM a la instancia de AWS, en el caso de EMR, deben tener instrucciones para conectarse al master node (conectarse por SSH Key también se vale, pero les quita algunos puntos). 

Si son nuevos en Terraform, no pasa nada, acá les dejo una guía que pueden usar.


