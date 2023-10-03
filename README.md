# Terraform modularisation spike

This repo contains the output of [the spike into terratest for infrastructure testing](https://github.com/ministryofjustice/data-platform/issues/533).

This demonstrates two changes:

1. Splitting our terraform into several independant modules
2. Integration testing API endpoints using terraform

The terraform code is based on the [existing terraform within the modernisaition-platform repo](https://github.com/ministryofjustice/modernisation-platform-environments/tree/03f6413f89aa68a16ed9dc304872707f5d741255/terraform/environments/data-platform). If we proceed with this approach, we will need to migrate the modules back into that repo. (See the [draft PR](https://github.com/ministryofjustice/modernisation-platform-environments/pull/3532) for what this might look like.)

An earlier investigation comparing terratest and "Python Test Helper for Terraform" can be found at: https://github.com/MatMoore/terraform-testing-examples

## How the module structure works

The terraform has been split up into modules, such that we are able to deploy each module separately and independently from the modernisation-platform environments.

We shouldn't need to create a separate module for everything, but for testing purposes we want to have modules for each API endpoint (or logical group of endpoints), so that we can test them in isolation. This will allow us to quickly narrow down on what's broken when we commit breaking changes to the terraform.

We may also consider creating a module for the S3 bucket structure (landing zone, data, metadata), and testing that the correct policies are applied, logging is enabled etc.

When we run a normal terraform deploy, the root module will require all the modules and configure them for the modernisation-platform (although here we have hardcoded things for the data-engineering-sandbox instead)

    .                                              <-- root module
    ├── api.tf
    ├── application_variables.auto.tfvars.json
    ├── iam.tf
    ├── locals.tf
    ├── modules
    │   ├── api_core                               <-- API resources everything else depends on
    │   └── api_data_product_ingest                <-- modules that configure different API endpoints
    │   └── another_api_endpoint
    │   └── yet_another_api_endpoint
    ├── platforms_locals.tf                        <-- in the root module, we still have environment-specific config
    ├── root.tf
    ├── s3.tf
    └── variables.tf

Within each module, we have the terratest tests (see [api_core/test](./modules/api_core/test) and [api_data_product_ingest/test](./modules/api_data_product_ingest/test/)).

Note: The tests depend on some extra terraform that defines the AWS provider and loads the module. This works with temporary sandbox credentials when running locally. If we integrate this with our CI we might need to change this to assume particular roles for the modernisation platform development environment. This terraform can also be used to deploy anything else the test may depend on, besides the module itself. E.g. in the case of api_core, the test terraform also defines a mock endpoint and creates a "test" stage for the API gateway.

## What the tests do

### api_core

Test that the module creates an API gateway with a working custom authorizer.

1. Run the terraform to create the API with a MOCK endpoint
2. Query the mock endpoint with a valid token
3. Check that it returned a 200 success response
4. Query the mock endpoint with an invalid token
5. Check that it returned a 403 response

### api_data_product_ingest

Test that the module creates a working upload endpoint.

1. Create a test bucket, and add a fake metadata file for the data product.
2. Create a temporary file
3. Run terraform to create the API with only the upload endpoint
4. Query the upload endpoint to get a presigned S3 URL
5. POST the file to the presigned URL
6. Check that the POST returned a 204 success response
7. Tear down the terraform and test bucket

## Prerequisites for running the tests

- Make sure [terraform](https://developer.hashicorp.com/terraform/downloads?product_intent=terraform) is installed and available on the path.
- [Install go](https://golang.org/).

## Run tests

```
cd modules/api_core/test
go test -v -timeout 30m
```

Warning: The long timeout is important, because if the test times out, the terraform destroy will not run, and you will have hanging resources.

Note: if you update or change any dependencies on 3rd party libraries, you need to run `go mod tidy` first.

## How terratest works

Terratest is a go library, so all the test code must be written in go.

Terratest can test various different kinds of infrastructure resources, but here we are using it to run terraform and interact with the resulting AWS resources.

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
3. Retrieve an IP/Domain and issue an HTTP request.

These tests do the latter, because we want to test that the API is responding correctly.

## Additional resources for Go

- [Tour of go](https://go.dev/tour/welcome/1)
- [Go by example](https://gobyexample.com/)
- [Go playground](https://go.dev/play/)
- [Go testing package](https://pkg.go.dev/testing)
