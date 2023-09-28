package terratest

import (
	"fmt"
	terra_test "github.com/gruntwork-io/terratest/modules/testing"
	"github.com/stretchr/testify/assert"
	"strconv"
	"strings"
	testing "testing"
	//"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/apigateway"
	terra_aws "github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

func TestApiGateway(t *testing.T) {
    awsRegion := "eu-west-2"
    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
	})
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)
    stageUrl := terraform.Output(t, terraformOptions,"deployment_invoke_url")
    time.Sleep(30 * time.Second)
    statusCode := DoGetRequest(t, stageUrl)
    assert.Equal(t, 200 , statusCode)
}

func DoGetRequest(t terra_test.TestingT, api string) int{
   resp, err := http.Get(api)
   if err != nil {
      log.Fatalln(err)
   }
   //We Read the response status on the line below.
   return resp.StatusCode
}
