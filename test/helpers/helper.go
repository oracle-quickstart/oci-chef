package helpers

import (
	"context"
	"encoding/json"
	"fmt"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/oracle/oci-go-sdk/common"
	"github.com/oracle/oci-go-sdk/example/helpers"
	"github.com/oracle/oci-go-sdk/objectstorage"
	"io/ioutil"
	"log"
)

type TFVarsProperties map[string]string

func FatalIfError(err error) {
	if err != nil {
		log.Fatalln(err.Error())
	}
}
func getNamespace(ctx context.Context, c objectstorage.ObjectStorageClient) string {
	request := objectstorage.GetNamespaceRequest{}
	r, err := c.GetNamespace(ctx, request)
	helpers.FatalIfError(err)
	fmt.Println("get namespace")
	return *r.Value
}

func GetKeyPairFromObjectStorage(bucketName string, sshPublicKeyObject string, sshPrivateKeyObject string) (*ssh.KeyPair, error) {
	c, e := objectstorage.NewObjectStorageClientWithConfigurationProvider(common.DefaultConfigProvider())
	FatalIfError(e)
	ctx := context.Background()
	namespace := getNamespace(ctx, c)
	sshPublicKey, e := getObject(ctx, c, namespace, bucketName, sshPublicKeyObject)
	FatalIfError(e)
	sshPrivateKey, e := getObject(ctx, c, namespace, bucketName, sshPrivateKeyObject)
	FatalIfError(e)
	return &ssh.KeyPair{PublicKey: string(sshPublicKey), PrivateKey: string(sshPrivateKey)}, e
}
func getObject(ctx context.Context, c objectstorage.ObjectStorageClient, namespace, bucketname, objectname string) ([]byte, error) {
	request := objectstorage.GetObjectRequest{
		NamespaceName: &namespace,
		BucketName:    &bucketname,
		ObjectName:    &objectname,
	}
	var response objectstorage.GetObjectResponse
	response, err := c.GetObject(ctx, request)
	helpers.FatalIfError(err)
	key, err := ioutil.ReadAll(response.Content)
	helpers.FatalIfError(err)
	return key, err
}

func GetJsonConfig(configPath string, configuration interface{}) error {
	raw, err := ioutil.ReadFile(configPath)
	if err != nil {
		return fmt.Errorf("Unable to read from configuration file: %s ", err.Error())
	}
	err = json.Unmarshal(raw, &configuration)
	if err != nil {
		return fmt.Errorf("Failed to parse configurations: %s ", err.Error())
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
