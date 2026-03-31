###############################################################
# Roboshop Components Module
###############################################################
# This Terraform block is used to create multiple Roboshop components
# (e.g., catalogue, user, cart, payment, etc.) using a reusable module.
#
# Instead of repeating module blocks for each service, we use a `for_each`
# loop to dynamically create all components based on the `var.components` map.
###############################################################


/*
# ----------------- OLD APPROACH (Single Component) -----------------
# Earlier, only one component was deployed at a time using a single module block.

module "components" {
    source        = "../../terraform-roboshop-component-infra"  # Local module path
    component     = var.component                          # Single component name (e.g., catalogue)
    rule_priority = var.rule_priority                      # Priority for the ALB rule
}
# ------------------------------------------------------------------
*/




# ----------------- NEW APPROACH (Multiple Components) -----------------
# Using for_each with a Git-based module source.
# This allows multiple components to be created dynamically.
# ----------------------------------------------------------------------

module "components" {

  # for_each iterates over the `var.components` map variable
  # Example of `var.components`:
  # {
  #   catalogue = { rule_priority = 10 }
  #   user      = { rule_priority = 20 }
  #   cart      = { rule_priority = 30 }
  # }

  for_each      = var.components
  source        = "git::https://github.com/venkatesh-thomm/terraform-roboshop-component.git?ref=dev"
  component     = each.key
  rule_priority = each.value.rule_priority
}
