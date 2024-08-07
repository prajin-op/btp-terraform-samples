###############################################################################################
# Setup of names in accordance to naming convention
###############################################################################################
resource "random_uuid" "uuid" {}

locals {
  random_uuid               = random_uuid.uuid.result
  project_subaccount_domain = "resillientapp-tf-sap-ms-${local.random_uuid}"
  project_subaccount_cf_org = substr(replace("${local.project_subaccount_domain}", "-", ""), 0, 32)
}

###############################################################################################
# Creation of subaccount
###############################################################################################
resource "btp_subaccount" "project" {
  name      = var.subaccount_name
  subdomain = local.project_subaccount_domain
  region    = lower(var.region)
}

###############################################################################################
# Assignment of users as sub account administrators
###############################################################################################
resource "btp_subaccount_role_collection_assignment" "subaccount-admins" {
  for_each             = toset("${var.subaccount_admins}")
  subaccount_id        = btp_subaccount.project.id
  role_collection_name = "Subaccount Administrator"
  user_name            = each.value
}

###############################################################################################
# Assignment of users as sub account service administrators
###############################################################################################
resource "btp_subaccount_role_collection_assignment" "subaccount-service-admins" {
  for_each             = toset("${var.subaccount_service_admins}")
  subaccount_id        = btp_subaccount.project.id
  role_collection_name = "Subaccount Service Administrator"
  user_name            = each.value
}

######################################################################
# Creation of Cloud Foundry environment
######################################################################
module "cloudfoundry_environment" {
  source                  = "../../modules/btp-cf/btp-cf-org-space"
  subaccount_id           = btp_subaccount.project.id
  instance_name           = local.project_subaccount_cf_org
  plan_name               = "standard"
  cf_org_name             = local.project_subaccount_cf_org
  cf_org_admins           = var.cf_org_admins
  cf_org_managers         = var.cf_org_admins
  cf_org_billing_managers = []
  cf_org_auditors         = []
  space_name              = var.space_name
  cf_org_id               = module.cloudfoundry_environment.cf_org_id
  cf_space_managers       = var.cf_space_managers
  cf_space_developers     = var.cf_space_developers
  cf_space_auditors       = var.cf_space_auditors
  origin                  = var.origin
}
######################################################################
# Entitlement of all services and apps
######################################################################
resource "btp_subaccount_entitlement" "name" {
  for_each = {
    for index, entitlement in var.entitlements :
    index => entitlement
  }
  subaccount_id = btp_subaccount.project.id
  service_name  = each.value.service_name
  plan_name     = each.value.plan_name
}

######################################################################
# Add "sleep" resource for generic purposes
######################################################################
resource "time_sleep" "wait_a_few_seconds" {
  depends_on      = [btp_subaccount_entitlement.name]
  create_duration = "30s"
}

######################################################################
# Create service instances (and service keys when needed)
######################################################################
# connectivitiy
module "create_cf_service_instance_connectivity" {
  depends_on            = [time_sleep.wait_a_few_seconds, module.cloudfoundry_environment]
  source                = "../../modules/btp-cf/serviceinstance_btp_cf"
  cf_space_id           = module.cloudfoundry_environment.cf_space_id
  service_name          = "connectivity"
  service_instance_name = "resapp-connectivity"
  plan_name             = "lite"
  type                  = "managed"
  parameters            = null
}

# destination
module "create_cf_service_instance_destination" {
  depends_on            = [time_sleep.wait_a_few_seconds, module.cloudfoundry_environment]
  source                = "../../modules/btp-cf/serviceinstance_btp_cf"
  cf_space_id           = module.cloudfoundry_environment.cf_space_id
  service_name          = "destination"
  service_instance_name = "resapp-destination"
  plan_name             = "lite"
  type                  = "managed"
  parameters            = null
}

# html5-apps-repo
module "create_cf_service_instance_html5_repo" {
  depends_on            = [time_sleep.wait_a_few_seconds, module.cloudfoundry_environment]
  source                = "../../modules/btp-cf/serviceinstance_btp_cf"
  cf_space_id           = module.cloudfoundry_environment.cf_space_id
  service_name          = "html5-apps-repo"
  service_instance_name = "resapp-html5-apps-repo"
  plan_name             = "app-host"
  type                  = "managed"
  parameters            = null
}

# enterprise-messaging
module "create_cf_service_instance_ems" {
  depends_on            = [time_sleep.wait_a_few_seconds, module.cloudfoundry_environment]
  source                = "../../modules/btp-cf/serviceinstance_btp_cf"
  cf_space_id           = module.cloudfoundry_environment.cf_space_id
  service_name          = "enterprise-messaging"
  service_instance_name = "resapp-enterprise-messaging"
  plan_name             = "default"
  type                  = "managed"
  parameters = jsonencode(
    {
      "emname" : "tfe",
      "namespace" : "tfe/bpem/em",
      "version" : "1.1.0",
      "resources" : {
        "units" : "10"
      },
      "options" : {
        "management" : true,
        "messagingrest" : true,
        "messaging" : true
      },
      "rules" : {

      }
    }
  )
}

#application-logs
module "create_cf_service_instance_applog" {
  depends_on            = [time_sleep.wait_a_few_seconds, module.cloudfoundry_environment]
  source                = "../../modules/btp-cf/serviceinstance_btp_cf"
  cf_space_id           = module.cloudfoundry_environment.cf_space_id
  service_name          = "application-logs"
  service_instance_name = "resapp-application-logs"
  plan_name             = "lite"
  type                  = "managed"
  parameters            = null
}

# xsuaa
module "create_cf_service_instance_xsuaa" {
  depends_on            = [time_sleep.wait_a_few_seconds, module.cloudfoundry_environment]
  source                = "../../modules/btp-cf/serviceinstance_btp_cf"
  cf_space_id           = module.cloudfoundry_environment.cf_space_id
  service_name          = "xsuaa"
  service_instance_name = "resapp-xsuaa"
  plan_name             = "application"
  type                  = "managed"
  parameters            = null
}

# hana-cloud
module "create_cf_service_instance_hana_cloud" {
  depends_on            = [time_sleep.wait_a_few_seconds, module.cloudfoundry_environment]
  source                = "../../modules/btp-cf/serviceinstance_btp_cf"
  cf_space_id           = module.cloudfoundry_environment.cf_space_id
  service_name          = "hana-cloud"
  service_instance_name = "resapp-hana-cloud"
  plan_name             = "hana"
  type                  = "managed"
  parameters = jsonencode(
    {
      "data" : {
        "memory" : 32,
        "edition" : "cloud",
        "systempassword" : "Abcd1234",
        "additionalWorkers" : 0,
        "disasterRecoveryMode" : "no_disaster_recovery",
        "enabledservices" : {
          "docstore" : false,
          "dpserver" : true,
          "scriptserver" : false
        },
        "requestedOperation" : {},
        "serviceStopped" : false,
        "slaLevel" : "standard",
        "storage" : 120,
        "vcpu" : 2,
        "whitelistIPs" : ["0.0.0.0/0"]
      }
  })
}

# hana
module "create_cf_service_instance_hdishared" {
  depends_on            = [time_sleep.wait_a_few_seconds, module.cloudfoundry_environment, module.create_cf_service_instance_hana_cloud]
  source                = "../../modules/btp-cf/serviceinstance_btp_cf"
  cf_space_id           = module.cloudfoundry_environment.cf_space_id
  service_name          = "hana"
  service_instance_name = "resapp-hana"
  plan_name             = "hdi-shared"
  type                  = "managed"
  parameters            = null
}

# autoscaler
module "create_cf_service_instance_autoscaler" {
  depends_on            = [time_sleep.wait_a_few_seconds, module.cloudfoundry_environment]
  source                = "../../modules/btp-cf/serviceinstance_btp_cf"
  cf_space_id           = module.cloudfoundry_environment.cf_space_id
  service_name          = "autoscaler"
  service_instance_name = "resapp-autoscaler"
  plan_name             = "standard"
  type                  = "managed"
  parameters            = null
}

######################################################################
# Create app subscriptions
######################################################################
resource "btp_subaccount_subscription" "app" {
  subaccount_id = btp_subaccount.project.id
  for_each = {
    for index, entitlement in var.entitlements :
    index => entitlement if contains(["app"], entitlement.type)
  }

  app_name   = each.value.service_name
  plan_name  = each.value.plan_name
  depends_on = [btp_subaccount_entitlement.name]
}

# # Create service key for Cloudfoundry service instance of enterprise-messaging
resource "cloudfoundry_service_credential_binding" "key_enterprise-messaging" {
  depends_on       = [time_sleep.wait_a_few_seconds, module.cloudfoundry_environment]
  name             = "key_enterprise-messaging"
  type             = "key"
  service_instance = module.create_cf_service_instance_ems.id
}