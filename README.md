# DevOps Exercise

This terraform configuration creates a web app behind an ELB
with self signed certificates.

# WARNING
This project creates cloud resources which will be billed, please
make sure to run the `teardown.sh` script after you are done.

## Pre-requisite
This project requires terraform to be installed on your workstation.
See https://learn.hashicorp.com/terraform/getting-started/install.html.

The project also requires a configured aws profile.
See https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html

## Start
Run:
export AWS_PROFILE=<profile>
./init.sh

## Check the App

# Tear down
When you are done please run the command below to tear down all cloud
resources created by init.
export AWS_PROFILE=<profile>
./teardown.sh
