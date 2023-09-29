package test

import (
	"fmt"
	"io"
	"log"
	"net/http"
	testing "testing"

	terra_test "github.com/gruntwork-io/terratest/modules/testing"
	"github.com/stretchr/testify/assert"

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
	gatewayId := terraform.Output(t, terraformOptions, "gateway_id")
	stageUrl := fmt.Sprintf("https://%s.execute-api.eu-west-2.amazonaws.com/", gatewayId)
	statusCode := DoGetRequest(t, stageUrl)
	assert.Equal(t, 200, statusCode)
}

func DoGetRequest(t terra_test.TestingT, api string) int {
	client := &http.Client{}

	req, err := http.NewRequest("GET", api, nil)
	if err != nil {
		log.Fatalln(err)
	}

	req.Header.Add("authorizationToken", "Bearer placeholder")

	resp, err := client.Do(req)
	if err != nil {
		log.Fatalln(err)
	}

	if resp.StatusCode != 200 {
		b, _ := io.ReadAll(resp.Body)
		println("body " + string(b))
	}

	return resp.StatusCode
}
