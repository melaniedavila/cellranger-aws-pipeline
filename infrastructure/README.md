# Infrastructure

We manage the AWS infrastructure that implements the cellranger
pipeline is using Terraform. This directory contains Terraform
definitions of all of our AWS resources. Changes to AWS resources
should be made by modifying the files in this directory and then
running `terraform apply`; changes should also be committed so that we
can track changes to our AWS configuration.

## Omissions

The S3 buckets that the pipeline reads from and writes to are not
defined here, as those S3 buckets are not only consumed by the
pipeline.

## Prereqs

* AWS credentials stored locally in `~/.aws/credentials`. If that file
  doesn't exist, run `aws configure` and follow the steps.
* [The Terraform CLI](https://www.terraform.io/intro/getting-started/install.html).

## Development

First:

* Ensure that your local copy of this repo is up-to-date with
  `origin/master`. You can run, for example, `git checkout master &&
  git pull`.
* From this repo's `infrastructure` directory, run `terraform
  apply`. You should see some output indicating that all of our AWS
  resources are up-to-date with the definitions in this repo.

Now you're ready to start making changes to our Terraform files. Make
your changes and then run `terraform plan -var-file=./dev.tfvars` to
see changes would take place; once you've made certain that all the
changes shown are intentional, run `terraform apply
-var-file=./dev.tfvars`.

Once you've validated that your changes work, run `terraform fmt`,
commit your changes and get them into `master` (preferably by opening
a PR and having someone approve your changes before merging into
`master`). After merging your changes into master, apply them to the
prod pipeline as you did the dev pipleline using `terraform plan` and
`terraform apply` with the `prod.tfvars` file. You'll also need to
`terraform workspace select prod` before doing any of that, and
`terraform workspace select default` when you're done making changes
to prod.

## Production

The prod pipeline is not to be developed against. Only stable changes
that are present in the master branch should be applied to prod, and
the prod pipeline should always be in-sync with master.

## Shared Resources

Note that some AWS resources, such as the ECR repos and the VPC, are
shared between the dev and prod terraform workspaces.

### Tips

You can use the Terraform CLI's `-target` option to specify a
particular resource to create, update, or destroy. This is especially
useful when sifting through a large batch of changes, so as to not
apply them all at once.

## Common errors

### "Cannot delete, found existing JobQueue relationship"

Run `terraform destroy -target=aws_batch_job_queue.this` and then
re-run `terraform apply`.
