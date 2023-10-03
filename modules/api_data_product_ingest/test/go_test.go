package test

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"mime/multipart"
	"net/http"
	"os"
	"strings"
	testing "testing"
	"time"

	"github.com/stretchr/testify/assert"

	"github.com/gruntwork-io/terratest/modules/random"
	terra_test "github.com/gruntwork-io/terratest/modules/testing"

	awsSdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

type Response struct {
	URL struct {
		Url    string
		Fields map[string]string
	}
}

func TestUploadingEmptyFileViaPresignedUrl(t *testing.T) {
	dataProductName := "example_prison_data_product"
	uniqueId := random.UniqueId()

	// Create an empty data file
	emptyFile := getTestFileName()
	defer os.Remove(emptyFile)

	// Create the landing bucket
	bucketId := fmt.Sprintf("data-platform-landing-zone-%s", strings.ToLower(uniqueId))
	aws.CreateS3Bucket(t, "eu-west-2", bucketId)
	EmulateDataProductRegistration(t, "eu-west-2", bucketId, dataProductName)

	// Run the terraform
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "test_terraform",
		Vars: map[string]interface{}{
			"environment": fmt.Sprintf("terratest-%s", uniqueId),
			"bucket_id":   bucketId,
		},
	})
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
	time.Sleep(30 * time.Second)

	// Attempt to upload the file
	gatewayId := terraform.Output(t, terraformOptions, "gateway_id")
	stageUrl := fmt.Sprintf("https://%s.execute-api.eu-west-2.amazonaws.com/test/upload_data?database=%s&table=%s&contentMD5=%s", gatewayId, dataProductName, "testing", "1B2M2Y8AsgTpgAmY7PhCfg==")
	response, err := GetResponse(t, stageUrl, "placeholder")
	if err != nil {
		t.Fatal(err)
	}
	statusCode, err := PostToPresignedUrl(t, response, emptyFile)
	if err != nil {
		t.Fatal(err)
	}

	assert.Equal(t, 204, statusCode)
}

func EmulateDataProductRegistration(t terra_test.TestingT, region string, bucket string, dataProductName string) {
	s3Client := aws.NewS3Client(t, region)

	params := &s3.PutObjectInput{
		Bucket: awsSdk.String(bucket),
		Key:    awsSdk.String(fmt.Sprintf("code/%s/metadata.json", dataProductName)), // Path will need updating
		Body:   awsSdk.ReadSeekCloser(strings.NewReader("")),
	}

	s3Client.PutObject(params)
}

func getTestFileName() string {
	emptyFile, err := os.CreateTemp("", "test-data-")
	if err != nil {
		log.Fatalln(err)
	}
	return emptyFile.Name()
}

// Note: this will change to POST
func GetResponse(t terra_test.TestingT, api string, token string) (Response, error) {
	client := &http.Client{}

	log.Println(api)

	req, err := http.NewRequest("GET", api, nil)
	if err != nil {
		return Response{}, err
	}

	req.Header.Add("authorizationToken", token)

	resp, err := client.Do(req)
	if err != nil {
		return Response{}, err
	}

	b, err := io.ReadAll(resp.Body)
	if err != nil {
		return Response{}, err
	}

	if resp.StatusCode != 200 {
		logHeaders(resp.Header)
	}

	log.Println("body: " + string(b))

	var result Response
	err = json.Unmarshal([]byte(b), &result)
	if err != nil {
		return result, err
	}

	return result, nil
}

func PostToPresignedUrl(t terra_test.TestingT, presignedUrlResponse Response, dataFile string) (int, error) {
	url := presignedUrlResponse.URL.Url
	formData := presignedUrlResponse.URL.Fields

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	for key, val := range formData {
		log.Println(fmt.Sprintf("Adding field '%s'", key))
		err := writer.WriteField(key, val)
		if err != nil {
			return 0, err
		}
	}

	_, err := writer.CreateFormFile("file", dataFile)
	if err != nil {
		return 0, err
	}

	writer.Close()

	client := &http.Client{}

	log.Println(body)
	req, err := http.NewRequest("POST", url, body)
	if err != nil {
		return 0, err
	}

	req.Header.Set("Content-Type", writer.FormDataContentType())

	resp, err := client.Do(req)
	if err != nil {
		return 0, err
	}

	if resp.StatusCode != 200 {
		log.Println("-----")
		logHeaders(resp.Header)
		b, err := io.ReadAll(resp.Body)
		if err == nil {
			log.Println("body: " + string(b))
		}
	}

	return resp.StatusCode, nil
}

func logHeaders(headers http.Header) {
	for name, values := range headers {
		for _, value := range values {
			log.Println(name, value)
		}
	}
}
