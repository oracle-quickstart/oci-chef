package test

type Inputs struct {
	Tenancy_ocid            string `json:"tenancy_ocid"`
	User_ocid               string `json:"user_ocid"`
	Fingerprint             string `json:"fingerprint"`
	Private_key_path        string `json:"private_key_path"`
	Region                  string `json:"region"`
	Compartment_ocid        string `json:"compartment_ocid"`
	Ssh_authorized_keys     string `json:"ssh_authorized_keys"`
	Ssh_private_key         string `json:"ssh_private_key"`
	Chef_user_name          string `json:"chef_user_name"`
	Chef_user_fist_name     string `json:"chef_user_fist_name"`
	Chef_user_last_name     string `json:"chef_user_last_name"`
	Chef_user_email         string `json:"chef_user_email"`
	Chef_user_password      string `json:"chef_user_password"`
	Chef_org_short_name     string `json:"chef_org_short_name"`
	Chef_org_full_name      string `json:"chef_org_full_name"`
	Bastion_private_key     string `json:"bastion_private_key"`
	Bastion_authorized_keys string `json:"bastion_authorized_keys"`
}
