package helpers

import (
	"github.com/oracle/oci-go-sdk/common"
	"os"
)

var (
	bareMetalShape string
)

func ParseEnvironmentVariables() {
	bareMetalShape = os.Getenv("BARE_METAL_SHAPE")
	if len(bareMetalShape) == 0 {
		bareMetalShape = "BM.HighIO1.36"
	}

}

func BareMetalShape() *string {
	return common.String(bareMetalShape)
}
