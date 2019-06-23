# Infrastructure

We manage the AWS infrastructure that implements the cellranger
pipeline is using Terraform. This directory contains Terraform
definitions of all of our AWS resources. Changes to AWS resources
should be made by modifying the files in this directory and then
running `terraform apply`; changes should also be committed so that we
can track changes to our AWS configuration.

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
your changes and then run `terraform plan` to see changes would take
place; once you've made certain that all the changes shown are
intentional, run `terraform apply`.

Once you've validated that your changes work, run `terraform fmt`,
commit your changes and get them into `master` (preferably by opening
a PR and having someone approve your changes before merging into
`master`).

### Tips

You can use the Terraform CLI's `-target` option to specify a
particular resource to create, update, or destroy. This is especially
useful when sifting through a large batch of changes, so as to not
apply them all at once.

## Common errors

### "Cannot delete, found existing JobQueue relationship"

Run `terraform destroy -target=aws_batch_job_queue.<name>` and then
re-run `terraform apply`.
