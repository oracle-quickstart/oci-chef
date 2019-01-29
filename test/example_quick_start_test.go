package test

import (
	"encoding/json"
	"fmt"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"log"
	"os"
	"strings"
	"terraform-oci-chef/test/helpers"
	"testing"
)

func Setup(t *testing.T, terraformOptions *terraform.Options) {
	test_structure.RunTestStage(t, "terraform_init", func() {
		terraform.Init(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "terraform_apply", func() {
		terraform.Apply(t, terraformOptions)
	})
}
func Teardown(t *testing.T, terraformOptions *terraform.Options) {
	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	test_structure.RunTestStage(t, "terraform_destroy", func() {
		terraform.Destroy(t, terraformOptions)
	})
}
func getEnvVars(args ...string) map[string]interface{} {
	result := make(map[string]interface{})
	for _, arg := range args {
		value, exist := os.LookupEnv("TF_VAR_" + arg)
		if exist {
			result[arg] = value
		}
	}
	return result
}
func GetTerraformOptions(TerraformDir string, Vars map[string]interface{}) *terraform.Options {
	var inputs Inputs
	err := helpers.GetJsonConfig(*helpers.JsonConfigFile(), &inputs)
	if err != nil {
		log.Println(err)
	}
	var jsonVars map[string]interface{}
	jsonVars = helpers.GetJsonVars(inputs)
	var tfVarNames = []string{"tenancy_ocid", "user_ocid", "fingerprint", "private_key_path", "region", "compartment_ocid", "chef_user_password"}
	var envVars = getEnvVars(tfVarNames...)
	terraformOptions := &terraform.Options{
		TerraformDir:             TerraformDir,
		Vars:                     helpers.MergeVars(jsonVars, envVars, Vars),
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
	defer test_structure.RunTestStage(t, "teardown", func() {
		Teardown(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "setup", func() {
		Setup(t, terraformOptions)
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
	defer test_structure.RunTestStage(t, "teardown", func() {
		Teardown(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "setup", func() {
		Setup(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "validate", func() {
		sshUserName := terraform.Output(t, terraformOptions, "ssh_user")
		bastionUserName := terraform.Output(t, terraformOptions, "bastion_user")
		objectStorageSshKeys := terraform.OutputMap(t, terraformOptions, "object_storage_ssh_keys")
		serverKeyPair, err := helpers.GetKeyPairFromObjectStorage(objectStorageSshKeys["bucket"], objectStorageSshKeys["ssh_authorized_keys"], objectStorageSshKeys["ssh_private_key"])
		if err != nil {
			assert.NotNil(t, serverKeyPair)
		}
		bastionKeyPair, err := helpers.GetKeyPairFromObjectStorage(objectStorageSshKeys["bucket"], objectStorageSshKeys["bastion_authorized_keys"], objectStorageSshKeys["bastion_private_key"])
		if err != nil {
			assert.NotNil(t, bastionKeyPair)
		}
		bastion := ssh.Host{
			Hostname:    terraform.Output(t, terraformOptions, "bastion_public_ip"),
			SshKeyPair:  bastionKeyPair,
			SshUserName: bastionUserName,
		}
		server := ssh.Host{
			Hostname:    terraform.Output(t, terraformOptions, "chef_server_private_ip"),
			SshKeyPair:  serverKeyPair,
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
	defer test_structure.RunTestStage(t, "teardown", func() {
		Teardown(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "setup", func() {
		Setup(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "validate", func() {
		sshUserName := terraform.Output(t, terraformOptions, "ssh_user")
		bastionUserName := terraform.Output(t, terraformOptions, "bastion_user")
		objectStorageSshKeys := terraform.OutputMap(t, terraformOptions, "object_storage_ssh_keys")
		serverKeyPair, err := helpers.GetKeyPairFromObjectStorage(objectStorageSshKeys["bucket"], objectStorageSshKeys["ssh_authorized_keys"], objectStorageSshKeys["ssh_private_key"])
		if err != nil {
			assert.NotNil(t, serverKeyPair)
		}
		bastionKeyPair, err := helpers.GetKeyPairFromObjectStorage(objectStorageSshKeys["bucket"], objectStorageSshKeys["bastion_authorized_keys"], objectStorageSshKeys["bastion_private_key"])
		if err != nil {
			assert.NotNil(t, bastionKeyPair)
		}
		bastion := ssh.Host{
			Hostname:    terraform.Output(t, terraformOptions, "bastion_public_ip"),
			SshKeyPair:  bastionKeyPair,
			SshUserName: bastionUserName,
		}
		workstation := ssh.Host{
			Hostname:    terraform.Output(t, terraformOptions, "chef_workstation_private_ip"),
			SshKeyPair:  serverKeyPair,
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
	defer test_structure.RunTestStage(t, "teardown", func() {
		Teardown(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "setup", func() {
		Setup(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "validate", func() {
		sshUserName := terraform.Output(t, terraformOptions, "ssh_user")
		bastionUserName := terraform.Output(t, terraformOptions, "bastion_user")
		objectStorageSshKeys := terraform.OutputMap(t, terraformOptions, "object_storage_ssh_keys")
		serverKeyPair, err := helpers.GetKeyPairFromObjectStorage(objectStorageSshKeys["bucket"], objectStorageSshKeys["ssh_authorized_keys"], objectStorageSshKeys["ssh_private_key"])
		if err != nil {
			assert.NotNil(t, serverKeyPair)
		}
		bastionKeyPair, err := helpers.GetKeyPairFromObjectStorage(objectStorageSshKeys["bucket"], objectStorageSshKeys["bastion_authorized_keys"], objectStorageSshKeys["bastion_private_key"])
		if err != nil {
			assert.NotNil(t, bastionKeyPair)
		}
		bastion := ssh.Host{
			Hostname:    terraform.Output(t, terraformOptions, "bastion_public_ip"),
			SshKeyPair:  bastionKeyPair,
			SshUserName: bastionUserName,
		}
		nodes := terraform.OutputList(t, terraformOptions, "chef_node_private_ip")
		assert.Equal(t, terraformOptions.Vars["chef_node_count"], len(nodes))
		for _, node := range nodes {
			chefNode := ssh.Host{
				Hostname:    node,
				SshKeyPair:  serverKeyPair,
				SshUserName: sshUserName,
			}
			cmdReturn := ssh.CheckPrivateSshConnection(t, bastion, chefNode, "sudo systemctl is-active httpd.service")
			assert.Equal(t, "active", strings.TrimSuffix(cmdReturn, "\n"))
		}
	})

}
func TestQuickStartHttpService(t *testing.T) {
	terraformOptions := GetTerraformOptions("../examples/quick_start", map[string]interface{}{})
	defer test_structure.RunTestStage(t, "teardown", func() {
		Teardown(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "setup", func() {
		Setup(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "validate", func() {
		bastionUserName := terraform.Output(t, terraformOptions, "bastion_user")
		objectStorageSshKeys := terraform.OutputMap(t, terraformOptions, "object_storage_ssh_keys")
		serverKeyPair, err := helpers.GetKeyPairFromObjectStorage(objectStorageSshKeys["bucket"], objectStorageSshKeys["ssh_authorized_keys"], objectStorageSshKeys["ssh_private_key"])
		if err != nil {
			assert.NotNil(t, serverKeyPair)
		}
		bastionKeyPair, err := helpers.GetKeyPairFromObjectStorage(objectStorageSshKeys["bucket"], objectStorageSshKeys["bastion_authorized_keys"], objectStorageSshKeys["bastion_private_key"])
		if err != nil {
			assert.NotNil(t, bastionKeyPair)
		}
		bastion := ssh.Host{
			Hostname:    terraform.Output(t, terraformOptions, "bastion_public_ip"),
			SshKeyPair:  bastionKeyPair,
			SshUserName: bastionUserName,
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
	defer test_structure.RunTestStage(t, "teardown", func() {
		Teardown(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "setup", func() {
		Setup(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "validate", func() {
		sshUserName := terraform.Output(t, terraformOptions, "ssh_user")
		bastionUserName := terraform.Output(t, terraformOptions, "bastion_user")
		objectStorageSshKeys := terraform.OutputMap(t, terraformOptions, "object_storage_ssh_keys")
		serverKeyPair, err := helpers.GetKeyPairFromObjectStorage(objectStorageSshKeys["bucket"], objectStorageSshKeys["ssh_authorized_keys"], objectStorageSshKeys["ssh_private_key"])
		if err != nil {
			assert.NotNil(t, serverKeyPair)
		}
		bastionKeyPair, err := helpers.GetKeyPairFromObjectStorage(objectStorageSshKeys["bucket"], objectStorageSshKeys["bastion_authorized_keys"], objectStorageSshKeys["bastion_private_key"])
		if err != nil {
			assert.NotNil(t, bastionKeyPair)
		}
		bastion := ssh.Host{
			Hostname:    terraform.Output(t, terraformOptions, "bastion_public_ip"),
			SshKeyPair:  bastionKeyPair,
			SshUserName: bastionUserName,
		}
		nodes := terraform.OutputList(t, terraformOptions, "chef_node_private_ip")
		assert.Equal(t, terraformOptions.Vars["chef_node_count"], len(nodes))
		for _, node := range nodes {
			chefNode := ssh.Host{
				Hostname:    node,
				SshKeyPair:  serverKeyPair,
				SshUserName: sshUserName,
			}
			cmdReturn := ssh.CheckPrivateSshConnection(t, bastion, chefNode, "sudo systemctl is-active httpd.service")
			assert.Equal(t, "active", strings.TrimSuffix(cmdReturn, "\n"))
		}
	})
}
func TestQuickStartChefNodeScaleDown(t *testing.T) {
	terraformOptions := GetTerraformOptions("../examples/quick_start", map[string]interface{}{"chef_node_count": 1})
	defer test_structure.RunTestStage(t, "teardown", func() {
		Teardown(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "setup", func() {
		Setup(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "validate", func() {
		sshUserName := terraform.Output(t, terraformOptions, "ssh_user")
		bastionUserName := terraform.Output(t, terraformOptions, "bastion_user")
		objectStorageSshKeys := terraform.OutputMap(t, terraformOptions, "object_storage_ssh_keys")
		serverKeyPair, err := helpers.GetKeyPairFromObjectStorage(objectStorageSshKeys["bucket"], objectStorageSshKeys["ssh_authorized_keys"], objectStorageSshKeys["ssh_private_key"])
		if err != nil {
			assert.NotNil(t, serverKeyPair)
		}
		bastionKeyPair, err := helpers.GetKeyPairFromObjectStorage(objectStorageSshKeys["bucket"], objectStorageSshKeys["bastion_authorized_keys"], objectStorageSshKeys["bastion_private_key"])
		if err != nil {
			assert.NotNil(t, bastionKeyPair)
		}
		bastion := ssh.Host{
			Hostname:    terraform.Output(t, terraformOptions, "bastion_public_ip"),
			SshKeyPair:  bastionKeyPair,
			SshUserName: bastionUserName,
		}
		workstation := ssh.Host{
			Hostname:    terraform.Output(t, terraformOptions, "chef_workstation_private_ip"),
			SshKeyPair:  serverKeyPair,
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
	defer test_structure.RunTestStage(t, "teardown", func() {
		Teardown(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "setup", func() {
		Setup(t, terraformOptions)
	})
	test_structure.RunTestStage(t, "validate", func() {
		// Run `terraform output` to get the value of an output variable
		chefServer := terraform.Output(t, terraformOptions, "chef_server_private_ip")
		// Verify we're getting back the variable we expect
		assert.NotEmpty(t, chefServer)
	})

}
