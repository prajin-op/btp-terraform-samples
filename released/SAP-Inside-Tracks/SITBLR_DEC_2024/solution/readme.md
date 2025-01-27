
# Terramate Setup for BTP and CF Providers

This guide provides a step-by-step process to create a Terramate-based setup for managing **BTP (Business Technology Platform)** and **CF (Cloud Foundry)** Terraform providers across **dev**, **staging**, and **production** environments.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed on your system.
- [Terramate CLI](https://terramate.io/) installed.
- Git for version control.
- Credentials for BTP and CF providers.

---

## Directory Structure

Create the following directory structure for your Terramate setup:

```plaintext
terramate_project/
├── modules/                 # Shared modules for reusable components
│   ├── btp/
│   │   ├── variables.tf
│   │   ├── provider.tf
│   │   ├── outputs.tf
│   ├── cf/
│       ├── variables.tf
│       ├── provider.tf
│       ├── outputs.tf
├── stacks/                  # Environment-specific configurations
│   ├── dev/
│   │   ├── terramate.tm.hcl
│   │   ├── main.tf
│   ├── staging/
│   │   ├── terramate.tm.hcl
│   │   ├── main.tf
│   ├── production/
│       ├── terramate.tm.hcl
│       ├── main.tf
└── terramate.tm.hcl         # Root-level Terramate configuration
```

---

## Step 1: Create Shared Modules

### **BTP Module**

**`modules/btp/variables.tf`**:
```hcl
variable "client_id" {
  type = string
}

variable "client_secret" {
  type = string
}

variable "subdomain" {
  type = string
}
```

**`modules/btp/provider.tf`**:
```hcl
provider "btp" {
  client_id     = var.client_id
  client_secret = var.client_secret
  subdomain     = var.subdomain
}
```

**`modules/btp/outputs.tf`**:
```hcl
output "btp_status" {
  value = "BTP Provider initialized for ${var.subdomain}"
}
```

### **CF Module**

**`modules/cf/variables.tf`**:
```hcl
variable "api_url" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type = string
}

variable "organization" {
  type = string
}

variable "space" {
  type = string
}
```

**`modules/cf/provider.tf`**:
```hcl
provider "cloudfoundry" {
  api_url      = var.api_url
  username     = var.username
  password     = var.password
  organization = var.organization
  space        = var.space
}
```

**`modules/cf/outputs.tf`**:
```hcl
output "cf_status" {
  value = "Cloud Foundry Provider initialized for ${var.organization}/${var.space}"
}
```

---

## Step 2: Configure Environment-Specific Stacks

Each stack (e.g., `dev`, `staging`, `production`) uses the shared modules with stack-specific variable overrides.

### **Stack: Dev**

**`stacks/dev/terramate.tm.hcl`**:
```hcl
terramate {
  name = "dev-stack"
}

globals {
  btp_client_id     = "dev-client-id"
  btp_client_secret = "dev-secret"
  btp_subdomain     = "dev-subdomain"

  cf_api_url        = "https://api.dev.example.com"
  cf_username       = "dev-user"
  cf_password       = "dev-password"
  cf_organization   = "dev-org"
  cf_space          = "dev-space"
}
```

**`stacks/dev/main.tf`**:
```hcl
module "btp" {
  source        = "../../modules/btp"
  client_id     = terramate.globals.btp_client_id
  client_secret = terramate.globals.btp_client_secret
  subdomain     = terramate.globals.btp_subdomain
}

module "cf" {
  source        = "../../modules/cf"
  api_url       = terramate.globals.cf_api_url
  username      = terramate.globals.cf_username
  password      = terramate.globals.cf_password
  organization  = terramate.globals.cf_organization
  space         = terramate.globals.cf_space
}
```

### **Other Stacks**
- Repeat the above steps for `staging` and `production`, overriding variables as needed in `terramate.tm.hcl`.

---

## Step 3: Root-Level Configuration

Create the root `terramate.tm.hcl` for shared settings and hooks:

**`terramate.tm.hcl`**:
```hcl
terramate {
  generate_code = true
}

globals {
  region = "us-east-1"  # Shared global settings
}
```

---

## Step 4: Automate with Terramate CLI

### **Initialize All Stacks**
Run the following command to initialize all stacks:
```bash
terramate run terraform init
```

### **Plan Across All Stacks**
Preview changes across all environments:
```bash
terramate run terraform plan
```

### **Apply Changes for a Specific Stack**
Apply changes in the `dev` stack:
```bash
terramate run --stack dev terraform apply
```

---

## Step 5: Add Automation Hooks (Optional)

You can define hooks in each `terramate.tm.hcl` to automate tasks, such as validation and notifications:

**Example Hook Configuration**:
```hcl
hooks {
  pre_plan  = ["./scripts/validate.sh"]
  post_apply = ["./scripts/notify.sh"]
}
```

---

## Conclusion

With this setup, you now have a scalable and modular Terramate configuration for managing **BTP** and **CF** providers across multiple environments. Use the shared modules for reusability, and leverage Terramate CLI for efficient stack orchestration.
