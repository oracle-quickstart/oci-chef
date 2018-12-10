package helpers

import (
	"bufio"
	"fmt"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"io/ioutil"
	"log"
	"os"
	"strings"
	"testing"
)

type TFVarsProperties map[string]string

func GetKeyPairFromFiles(ssh_public_key_path string, ssh_private_key_path string) (*ssh.KeyPair, error) {
	var err error
	ssh_public_key, e := ioutil.ReadFile(ssh_public_key_path)
	if e != nil {
		err = fmt.Errorf("Error reading ssh public key file \"%s\": %s", ssh_public_key_path, e.Error())
	} else {
		ssh_private_key, e := ioutil.ReadFile(ssh_private_key_path)
		if e != nil {
			err = fmt.Errorf("Error reading ssh private key file \"%s\": %s", ssh_private_key_path, e.Error())
		} else {
			return &ssh.KeyPair{PublicKey: string(ssh_public_key), PrivateKey: string(ssh_private_key)}, nil
		}
	}
	return nil, err
}
func ReadTFVarsFile(terraformDirectory string) (TFVarsProperties, error) {
	config := TFVarsProperties{}

	if len(terraformDirectory) == 0 {
		return config, nil
	}
	tfVars := "terraform.tfvars"
	file, err := os.Open(terraformDirectory + string(os.PathSeparator) + tfVars)
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
func GetKeyPairFromOptions(terraformOptions *terraform.Options, t *testing.T) (*ssh.KeyPair, error) {
	vars, err := ReadTFVarsFile(terraformOptions.TerraformDir)
	if err != nil {
		t.Error("Error while reading properties file")
		return nil, err
	}
	//keyPair, err := test_helper.GetKeyPairFromFiles(vars["ssh_authorized_keys"], vars["ssh_private_key"])
	keyPair, err := GetKeyPairFromFiles(vars["ssh_authorized_keys"], vars["ssh_private_key"])
	return keyPair, err
}
