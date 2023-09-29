package test

import (
	"fmt"
	"log"
	"net/http"
	testing "testing"

	terra_test "github.com/gruntwork-io/terratest/modules/testing"

	//"github.com/aws/aws-sdk-go/aws"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestApiGateway(t *testing.T) {
	uniqueId := random.UniqueId()
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "test_terraform",
		Vars: map[string]interface{}{
			"environment": fmt.Sprintf("terratest-%s", uniqueId),
		},
	})
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
	//stageUrl := terraform.Output(t, terraformOptions, "deployment_invoke_url")
	//statusCode := DoGetRequest(t, stageUrl)
	//assert.Equal(t, 200, statusCode)
}

func DoGetRequest(t terra_test.TestingT, api string) int {
	resp, err := http.Get(api)
	if err != nil {
		log.Fatalln(err)
	}
	//We Read the response status on the line below.
	return resp.StatusCode
}
