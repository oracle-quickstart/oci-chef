package helpers

import (
	"github.com/oracle/oci-go-sdk/common"
	"os"
)

var (
	bareMetalShape string
	jsonConfigFile string
)

func ParseEnvironmentVariables() {
	bareMetalShape = os.Getenv("BARE_METAL_SHAPE")
	if len(bareMetalShape) == 0 {
		bareMetalShape = "BM.HighIO1.36"
	}
	jsonConfigFile = os.Getenv("JSON_CONFIG_FILE")
	if len(jsonConfigFile) == 0 {
		jsonConfigFile = "inputs_config.json"
	}
}

func BareMetalShape() *string {
	return common.String(bareMetalShape)
}
func JsonConfigFile() *string {
	return common.String(jsonConfigFile)
}
