package test

import (
	"bufio"
	"encoding/json"
	"fmt"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"log"
	"os"
	"strings"
	"terraform-module-test-lib"
	"testing"
)

func TestQuickStart(t *testing.T) {

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../examples/quick_start",
		Vars:         map[string]interface{}{},

		NoColor: false,
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	//defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	chefServer := terraform.Output(t, terraformOptions, "chef_server_private_ip")
	// Verify we're getting back the variable we expect
	assert.NotEmpty(t, chefServer)

}
func TestQuickStartChefServer(t *testing.T) {
	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../examples/quick_start",
		Vars:         map[string]interface{}{},

		NoColor: false,
	}
	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.Apply(t, terraformOptions)

	vars, err := ReadTFVarsFile("../examples/quick_start/terraform.tfvars")
	if err != nil {
		t.Error("Error while reading properties file")
	}
	sshUserName := "opc"
	keyPair, err := test_helper.GetKeyPairFromFiles(vars["ssh_authorized_keys"], vars["ssh_private_key"])
	log.Println(err)
	if err != nil {
		assert.NotNil(t, keyPair)
	}
	bastion := ssh.Host{
		Hostname:    terraform.Output(t, terraformOptions, "bastion_public_ip"),
		SshKeyPair:  keyPair,
		SshUserName: sshUserName,
	}
	server := ssh.Host{
		Hostname:    terraform.Output(t, terraformOptions, "chef_server_private_ip"),
		SshKeyPair:  keyPair,
		SshUserName: sshUserName,
	}
	cmdReturn := ssh.CheckPrivateSshConnection(t, bastion, server, "sudo chef-server-ctl status")
	for _, line := range strings.Split(strings.TrimSuffix(cmdReturn, "\n"), "\n") {
		assert.True(t, strings.HasPrefix(line, "run"), line)
	}

}
func TestQuickStartChefWorkstation(t *testing.T) {

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../examples/quick_start",
		Vars:         map[string]interface{}{},

		NoColor: false,
	}
	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.Apply(t, terraformOptions)

	vars, err := ReadTFVarsFile("../examples/quick_start/terraform.tfvars")
	if err != nil {
		t.Error("Error while reading properties file")
	}
	sshUserName := "opc"
	keyPair, err := test_helper.GetKeyPairFromFiles(vars["ssh_authorized_keys"], vars["ssh_private_key"])
	log.Println(err)
	if err != nil {
		assert.NotNil(t, keyPair)
	}
	bastion := ssh.Host{
		Hostname:    terraform.Output(t, terraformOptions, "bastion_public_ip"),
		SshKeyPair:  keyPair,
		SshUserName: sshUserName,
	}
	workstation := ssh.Host{
		Hostname:    terraform.Output(t, terraformOptions, "chef_workstation_private_ip"),
		SshKeyPair:  keyPair,
		SshUserName: sshUserName,
	}
	cmdReturn := ssh.CheckPrivateSshConnection(t, bastion, workstation, "knife node list -F json")
	var nodes []string
	err = json.NewDecoder(strings.NewReader(cmdReturn)).Decode(&nodes)
	if err != nil {
		t.Error("Error while remote exec output")
	}
	log.Println(nodes)
	assert.Equal(t, 3, len(nodes))

}
func TestQuickStartChefNode(t *testing.T) {

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../examples/quick_start",
		Vars: map[string]interface{}{
			"chef_node_count": 3,
		},

		NoColor: false,
	}
	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.Apply(t, terraformOptions)

	vars, err := ReadTFVarsFile("../examples/quick_start/terraform.tfvars")
	if err != nil {
		t.Error("Error while reading properties file")
	}
	sshUserName := "opc"
	keyPair, err := test_helper.GetKeyPairFromFiles(vars["ssh_authorized_keys"], vars["ssh_private_key"])
	log.Println(err)
	if err != nil {
		assert.NotNil(t, keyPair)
	}
	bastion := ssh.Host{
		Hostname:    terraform.Output(t, terraformOptions, "bastion_public_ip"),
		SshKeyPair:  keyPair,
		SshUserName: sshUserName,
	}
	nodes := terraform.OutputList(t, terraformOptions, "chef_node_private_ip")
	assert.Equal(t, terraformOptions.Vars["chef_node_count"], len(nodes))
	for _, node := range nodes {
		chefNode := ssh.Host{
			Hostname:    node,
			SshKeyPair:  keyPair,
			SshUserName: sshUserName,
		}
		cmdReturn := ssh.CheckPrivateSshConnection(t, bastion, chefNode, "sudo systemctl is-active httpd.service")
		assert.Equal(t, "active", strings.TrimSuffix(cmdReturn, "\n"))
	}

}
func TestQuickStartHttpService(t *testing.T) {

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../examples/quick_start",
		Vars:         map[string]interface{}{},

		NoColor: false,
	}
	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.Apply(t, terraformOptions)

	vars, err := ReadTFVarsFile("../examples/quick_start/terraform.tfvars")
	if err != nil {
		t.Error("Error while reading properties file")
	}
	sshUserName := "opc"
	keyPair, err := test_helper.GetKeyPairFromFiles(vars["ssh_authorized_keys"], vars["ssh_private_key"])
	log.Println(err)
	if err != nil {
		assert.NotNil(t, keyPair)
	}
	bastion := ssh.Host{
		Hostname:    terraform.Output(t, terraformOptions, "bastion_public_ip"),
		SshKeyPair:  keyPair,
		SshUserName: sshUserName,
	}
	nodes := terraform.OutputList(t, terraformOptions, "chef_node_private_ip")
	for _, node := range nodes {
		cmdReturn := ssh.CheckSshCommand(t, bastion, fmt.Sprintf("curl -s -o /dev/null -w \"%%{http_code}\" http://%s/", node))
		assert.Equal(t, "200", cmdReturn)
	}

}
func TestQuickStartChefNodeScaleUp(t *testing.T) {

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../examples/quick_start",
		Vars: map[string]interface{}{
			"chef_node_count": 4,
		},

		NoColor: false,
	}
	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.Apply(t, terraformOptions)

	vars, err := ReadTFVarsFile("../examples/quick_start/terraform.tfvars")
	if err != nil {
		t.Error("Error while reading properties file")
	}
	sshUserName := "opc"
	keyPair, err := test_helper.GetKeyPairFromFiles(vars["ssh_authorized_keys"], vars["ssh_private_key"])
	log.Println(err)
	if err != nil {
		assert.NotNil(t, keyPair)
	}
	bastion := ssh.Host{
		Hostname:    terraform.Output(t, terraformOptions, "bastion_public_ip"),
		SshKeyPair:  keyPair,
		SshUserName: sshUserName,
	}
	nodes := terraform.OutputList(t, terraformOptions, "chef_node_private_ip")
	assert.Equal(t, terraformOptions.Vars["chef_node_count"], len(nodes))
	for _, node := range nodes {
		chefNode := ssh.Host{
			Hostname:    node,
			SshKeyPair:  keyPair,
			SshUserName: sshUserName,
		}
		cmdReturn := ssh.CheckPrivateSshConnection(t, bastion, chefNode, "sudo systemctl is-active httpd.service")
		assert.Equal(t, "active", strings.TrimSuffix(cmdReturn, "\n"))
	}
}
func TestQuickStartChefNodeScaleDown(t *testing.T) {

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../examples/quick_start",
		Vars: map[string]interface{}{
			"chef_node_count": 1,
		},

		NoColor: false,
	}
	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.Apply(t, terraformOptions)

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	vars, err := ReadTFVarsFile("../examples/quick_start/terraform.tfvars")
	if err != nil {
		t.Error("Error while reading properties file")
	}
	sshUserName := "opc"
	keyPair, err := test_helper.GetKeyPairFromFiles(vars["ssh_authorized_keys"], vars["ssh_private_key"])
	log.Println(err)
	if err != nil {
		assert.NotNil(t, keyPair)
	}
	bastion := ssh.Host{
		Hostname:    terraform.Output(t, terraformOptions, "bastion_public_ip"),
		SshKeyPair:  keyPair,
		SshUserName: sshUserName,
	}
	workstation := ssh.Host{
		Hostname:    terraform.Output(t, terraformOptions, "chef_workstation_private_ip"),
		SshKeyPair:  keyPair,
		SshUserName: sshUserName,
	}
	cmdReturn := ssh.CheckPrivateSshConnection(t, bastion, workstation, "knife node list -F json")
	var nodes []string
	err = json.NewDecoder(strings.NewReader(cmdReturn)).Decode(&nodes)
	if err != nil {
		t.Error("Error while remote exec output")
	}
	log.Println(nodes)
	assert.Equal(t, terraformOptions.Vars["chef_node_count"], len(nodes), strings.Join(nodes, ","))
}

func TestQuickStartWithShapeBM(t *testing.T) {
	t.Parallel()
	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../examples/quick_start",
		Vars: map[string]interface{}{
			"shape": "BM.HighIO1.36",
		},

		NoColor: false,
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	chefServer := terraform.Output(t, terraformOptions, "chef_server_private_ip")
	// Verify we're getting back the variable we expect
	assert.NotEmpty(t, chefServer)

}

type TFVarsProperties map[string]string

func ReadTFVarsFile(filename string) (TFVarsProperties, error) {
	config := TFVarsProperties{}

	if len(filename) == 0 {
		return config, nil
	}
	file, err := os.Open(filename)
	if err != nil {
		log.Fatal(err)
		return nil, err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if equal := strings.Index(line, "="); equal >= 0 {
			if key := strings.TrimSpace(line[:equal]); len(key) > 0 {
				value := ""
				if len(line) > equal {
					value = strings.TrimSuffix(strings.TrimPrefix(strings.TrimSpace(line[equal+1:]), "\""), "\"")
				}
				config[key] = value
			}
		}
	}

	if err := scanner.Err(); err != nil {
		log.Fatal(err)
		return nil, err
	}

	return config, nil
}
