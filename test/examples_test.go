package test

import (
	"./helpers"
	"os"
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
