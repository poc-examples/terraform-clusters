package test

import (
	"io/ioutil"
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"gopkg.in/yaml.v2"
)

type OpenShiftConfig struct {
	Openshift struct {
		AWS struct {
			Type        string `yaml:"type"`
			ClusterName string `yaml:"cluster_name"`
			Version     string `yaml:"version"`
			Region      string `yaml:"region"`
		} `yaml:"aws"`
		Admin struct {
			Credentials struct {
				Username string `yaml:"username"`
				Password string `yaml:"password"`
			} `yaml:"credentials"`
		} `yaml:"admin"`
		OfflineToken string `yaml:"offline_token"`
	} `yaml:"openshift"`
}

func TestRosaCluster(t *testing.T) {
	t.Parallel()

	// Load and parse the base-rosa YAML file
	useCasePath := filepath.Join("use-cases", "rosa", "base-rosa.yaml")
	yamlFile, err := ioutil.ReadFile(useCasePath)
	if err != nil {
		t.Fatalf("Failed to read YAML file: %v", err)
	}

	var config OpenShiftConfig
	err = yaml.Unmarshal(yamlFile, &config)
	if err != nil {
		t.Fatalf("Failed to parse YAML file: %v", err)
	}

	// Define Terraform options
	terraformOptions := &terraform.Options{
		TerraformDir: "../modules/aws-rosa",
		Vars: map[string]interface{}{
			"cluster_name": config.Openshift.AWS.ClusterName,
			"region":       config.Openshift.AWS.Region,
			"version":      config.Openshift.AWS.Version,
		},
	}

	// Clean up resources after the test
	defer terraform.Destroy(t, terraformOptions)

	// Run Terraform init and apply
	terraform.InitAndApply(t, terraformOptions)

	// Add validation steps (e.g., checking the outputs)
	apiURL := terraform.Output(t, terraformOptions, "api_url")
	if apiURL == "" {
		t.Fatalf("Expected non-empty API URL, got %s", apiURL)
	}
}
