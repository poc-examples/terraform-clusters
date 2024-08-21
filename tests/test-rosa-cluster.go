package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestROSACluster(t *testing.T) {
	// Define the Terraform options with the default path to Terraform code
	terraformOptions := &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: "../aws-rosa",
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// Run `terraform init` and `terraform apply`
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the values of output variables
	clusterId := terraform.Output(t, terraformOptions, "cluster_id")
	clusterUrl := terraform.Output(t, terraformOptions, "cluster_url")

	// Verify that the cluster was created and the output variables are not empty
	assert.NotEmpty(t, clusterId)
	assert.NotEmpty(t, clusterUrl)
}
