package helpers

import (
	"encoding/json"
	"fmt"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"io/ioutil"
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
func GetJsonConfig(configPath string, configuration interface{}) error {
	raw, err := ioutil.ReadFile(configPath)
	if err != nil {
		return fmt.Errorf("Unable to read from configuration file: %s", err.Error())
	}
	err = json.Unmarshal(raw, &configuration)
	if err != nil {
		return fmt.Errorf("Failed to parse configurations: %s", err.Error())
	}
	return nil
}
func GetJsonVars(configuration interface{}) map[string]interface{} {
	var result map[string]interface{}
	m, _ := json.Marshal(configuration)
	json.Unmarshal(m, &result)
	return result
}
func MergeVars(maps ...map[string]interface{}) map[string]interface{} {
	result := make(map[string]interface{})
	for _, m := range maps {
		for k, v := range m {
			if v != "" && v != nil {
				result[k] = v
			}
		}
	}
	return result
}
