# Terraform modularisation spike

This repo contains the output of [the spike into terratest for infrastructure testing](https://github.com/ministryofjustice/data-platform/issues/533).

The terraform code is based on the [existing terraform within the modernisaition-platform repo](https://github.com/ministryofjustice/modernisation-platform-environments/tree/03f6413f89aa68a16ed9dc304872707f5d741255/terraform/environments/data-platform). If we proceed with this approach, we will need to migrate the modules back into that repo.

An earlier investigation into terratest and Python Test Helper for Terraform (a more basic tool) can be found at: https://github.com/MatMoore/terraform-testing-examples

## How the module structure works

The terraform has been split up into modules, such that we can deploy each module separately and independently from the modernisation-platform environments

The root module must then require all the modules and configure them for the modernisation-platform (although here we have hardcoded things for the data-engineering-sandbox instead)

Within each module we can add terratest tests (see api-core for an example)

The tests depend on some extra terraform that defines the AWS provider and loads the module. This is set up so that developers can run it with temporary credentials for whatever environment they need. If we integrate this with our CI we might need to change this to assume particular roles.

In the case of api-core, the test terraform also defines a mock endpoint and deploys it.

## How terratest works

Terratest is a go library, so all the test code is written in go. It can test various different kinds of infrastructure resources, but here we are using it to run terraform and interact with the resulting AWS resources.

Tests live in files like \*\_test.go.

The core of each test looks like this:

```go
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/terraform-aws-hello-world-example",
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

    // ... make some assertions
```

To make the test stronger, you can swap out `InitAndApply` for `InitAndApplyIdempotent`, which applies the terraform module twice, and checks nothing changes.

There are different ways to assert against things in the test. In order of complexity:

1. Directly assert that module outputs (e.g. domains, IPs) match expected values
2. Retrieve IDs of AWS resources and interract with them via the [aws subpackage](https://pkg.go.dev/github.com/gruntwork-io/terratest@v0.43.13/modules/aws) ([example 1](https://github.com/gruntwork-io/terratest/blob/v0.43.13/test/terraform_aws_rds_example_test.go) [example 2](https://github.com/gruntwork-io/terratest/blob/v0.43.13/test/terraform_aws_s3_example_test.go)) (only possible for some services)
3. Retrieve an IP/Domain and issue an HTTP request, as demonstrated by the api-core tests.

## Prerequisites

Make sure [terraform](https://developer.hashicorp.com/terraform/downloads?product_intent=terraform) is installed and available on the path.

[Install go](https://golang.org/).

## Run tests

```
cd modules/api_core/test
go test -v -timeout 30m
```

Warning: The long timeout is important, because if the test times out, the terraform destroy will not run, and you will have hanging resources.
