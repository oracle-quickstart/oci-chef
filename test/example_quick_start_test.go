package test

import (
	"./helpers"
	"encoding/json"
	"fmt"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"log"
	"strings"
	"testing"
)

func SetupTeardown(t *testing.T, terraformOptions *terraform.Options) {
	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer test_structure.RunTestStage(t, "terraform_destroy", func() {
		terraform.Destroy(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "terraform_init", func() {
		terraform.Init(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "terraform_apply", func() {
		terraform.Apply(t, terraformOptions)
	})
}
func GetTerraformOptions(TerraformDir string, Vars map[string]interface{}) *terraform.Options {
	var inputs Inputs
	err := helpers.GetJsonConfig(*helpers.JsonConfigFile(), &inputs)
	if err != nil {
		log.Println(err)
	}
	var jsonVars map[string]interface{}
	jsonVars = helpers.GetJsonVars(inputs)
	terraformOptions := &terraform.Options{
		TerraformDir:             TerraformDir,
		Vars:                     helpers.MergeVars(jsonVars, Vars),
		EnvVars:                  nil,
		BackendConfig:            nil,
		RetryableTerraformErrors: nil,
		MaxRetries:               0,
		TimeBetweenRetries:       0,
		Upgrade:                  false,
		NoColor:                  false,
		SshAgent:                 nil,
	}
	return terraformOptions
}
func TestQuickStart(t *testing.T) {
	terraformOptions := GetTerraformOptions("../examples/quick_start", map[string]interface{}{})
	test_structure.RunTestStage(t, "setup_teardown", func() {
		SetupTeardown(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "validate", func() {
		// Run `terraform output` to get the value of an output variable
		chefServer := terraform.Output(t, terraformOptions, "chef_server_private_ip")
		// Verify we're getting back the variable we expect
		assert.NotEmpty(t, chefServer)
	})

}
func TestQuickStartChefServer(t *testing.T) {
	terraformOptions := GetTerraformOptions("../examples/quick_start", map[string]interface{}{})
	test_structure.RunTestStage(t, "setup_teardown", func() {
		SetupTeardown(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "validate", func() {
		sshUserName := "opc"
		keyPair, err := helpers.GetKeyPairFromOptions(terraformOptions, t)
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
	})

}
func TestQuickStartChefWorkstation(t *testing.T) {
	terraformOptions := GetTerraformOptions("../examples/quick_start", map[string]interface{}{})
	test_structure.RunTestStage(t, "setup_teardown", func() {
		SetupTeardown(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "validate", func() {
		sshUserName := "opc"
		keyPair, err := helpers.GetKeyPairFromOptions(terraformOptions, t)
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
	})

}
func TestQuickStartChefNode(t *testing.T) {
	terraformOptions := GetTerraformOptions("../examples/quick_start", map[string]interface{}{"chef_node_count": 3})
	test_structure.RunTestStage(t, "setup_teardown", func() {
		SetupTeardown(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "validate", func() {
		sshUserName := "opc"
		keyPair, err := helpers.GetKeyPairFromOptions(terraformOptions, t)
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
	})

}
func TestQuickStartHttpService(t *testing.T) {
	terraformOptions := GetTerraformOptions("../examples/quick_start", map[string]interface{}{})
	test_structure.RunTestStage(t, "setup_teardown", func() {
		SetupTeardown(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "validate", func() {
		sshUserName := "opc"
		keyPair, err := helpers.GetKeyPairFromOptions(terraformOptions, t)
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
	})

}
func TestQuickStartChefNodeScaleUp(t *testing.T) {
	terraformOptions := GetTerraformOptions("../examples/quick_start", map[string]interface{}{"chef_node_count": 4})
	test_structure.RunTestStage(t, "setup_teardown", func() {
		SetupTeardown(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "validate", func() {
		sshUserName := "opc"
		keyPair, err := helpers.GetKeyPairFromOptions(terraformOptions, t)
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
	})
}
func TestQuickStartChefNodeScaleDown(t *testing.T) {
	terraformOptions := GetTerraformOptions("../examples/quick_start", map[string]interface{}{"chef_node_count": 1})
	test_structure.RunTestStage(t, "setup_teardown", func() {
		SetupTeardown(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "validate", func() {
		sshUserName := "opc"
		keyPair, err := helpers.GetKeyPairFromOptions(terraformOptions, t)
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
	})
}
func TestQuickStartWithShapeBM(t *testing.T) {
	terraformOptions := GetTerraformOptions("../examples/quick_start", map[string]interface{}{"shape": *helpers.BareMetalShape()})
	test_structure.RunTestStage(t, "setup_teardown", func() {
		SetupTeardown(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "validate", func() {
		// Run `terraform output` to get the value of an output variable
		chefServer := terraform.Output(t, terraformOptions, "chef_server_private_ip")
		// Verify we're getting back the variable we expect
		assert.NotEmpty(t, chefServer)
	})

}
