terraform {
  required_providers {
    btp = {
      source  = "sap/btp"
      version = "~> 1.7.0"
    }
    cloudfoundry = {
      source  = "cloudfoundry-community/cloudfoundry"
      version = "0.53.1"
    }
  }
}

provider "btp" {
  globalaccount = var.globalaccount
}

// doesn't work for regions with multiple CF environments, e.g. eu10
// (https://help.sap.com/docs/btp/sap-business-technology-platform/regions)
provider "cloudfoundry" {
  api_url = "https://api.cf.${var.region}.hana.ondemand.com"
}