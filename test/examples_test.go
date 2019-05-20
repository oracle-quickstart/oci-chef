package test

import (
	"os"
	"terraform-oci-chef/test/helpers"
	"testing"
)

func TestMain(m *testing.M) {
	BeforeAll()
	ret := m.Run()
	AfterAll()
	os.Exit(ret)
}
func BeforeAll() {
	helpers.ParseEnvironmentVariables()
}
func AfterAll() {
}
