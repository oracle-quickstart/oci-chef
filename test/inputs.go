package test

type Inputs struct {
	Tenancy_ocid       string `json:"tenancy_ocid"`
	User_ocid          string `json:"user_ocid"`
	Fingerprint        string `json:"fingerprint"`
	Private_key_path   string `json:"private_key_path"`
	Region             string `json:"region"`
	Compartment_ocid   string `json:"compartment_ocid"`
	Chef_user_password string `json:"chef_user_password"`
}
