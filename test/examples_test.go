package test

import (
	"fmt"
	"github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestChefServer(t *testing.T) {

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../examples/chef_server",

		NoColor: false,
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	chefServer := terraform.Output(t, terraformOptions, "public_ip")
	// Verify we're getting back the variable we expect
	assert.NotEmpty(t, chefServer)

}

func TestChefServerWorkstationNode(t *testing.T) {

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../examples/chef_server_workstation_node",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"chef_node_count": "1",
		},

		NoColor: false,
	}

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	chefServer := terraform.Output(t, terraformOptions, "chef_server_public_ip")
	workStation := terraform.Output(t, terraformOptions, "chef_workstation_public_ip")
	chefNodes := terraform.OutputList(t, terraformOptions, "chef_node_public_ip")

	// Verify we're getting back the variable we expect
	assert.NotEmpty(t, chefServer)
	assert.NotEmpty(t, workStation)
	assert.NotEmpty(t, chefNodes)
	assert.Equal(t, 1, len(chefNodes))
	// Verify that we get back a 200 OK
	for _, chefNode := range chefNodes {
		httpUrl := "http://" + chefNode
		fmt.Println(httpUrl)
		http_helper.HttpGet(t, httpUrl)
	}
}
func TestScaleUpChefNode(t *testing.T) {
	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/chef_server_workstation_node",
		//scale chef node count from one to two
		Vars: map[string]interface{}{
			"chef_node_count": "2",
		},

		NoColor: false,
	}

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.Apply(t, terraformOptions)
	chefNodes := terraform.OutputList(t, terraformOptions, "chef_node_public_ip")
	assert.Equal(t, 2, len(chefNodes))
	// Verify that we get back a 200 OK
	for _, chefNode := range chefNodes {
		httpUrl := "http://" + chefNode
		fmt.Println(httpUrl)
		http_helper.HttpGet(t, httpUrl)
	}
}
func TestScaleDownChefNode(t *testing.T) {
	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/chef_server_workstation_node",
		//scale chef node count from one to two
		Vars: map[string]interface{}{
			"chef_node_count": "1",
		},

		NoColor: false,
	}
	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.Apply(t, terraformOptions)
	chefNodes := terraform.OutputList(t, terraformOptions, "chef_node_public_ip")
	assert.Equal(t, 1, len(chefNodes))
	// Verify that we get back a 200 OK
	for _, chefNode := range chefNodes {
		httpUrl := "http://" + chefNode
		fmt.Println(httpUrl)
		http_helper.HttpGet(t, httpUrl)
	}
}
