module "oidc_config_and_provider_hcp" {

  source  = "terraform-redhat/rosa-hcp/rhcs//modules/oidc-config-and-provider"
  version = "1.6.2"

  managed = true
  tags    = var.additional_tags
}
