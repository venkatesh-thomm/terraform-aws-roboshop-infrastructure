##############################################
# VARIABLES FOR COMPONENT CONFIGURATION
##############################################

# ---------------------------------------------------------------------------
# component
# ---------------------------------------------------------------------------
# This variable defines the default component name being deployed.
# It helps make the module reusable for multiple services (like catalogue, cart, user, etc.)
# Example: You can override this variable when applying the module to deploy different components.
# ---------------------------------------------------------------------------
variable "component" {
  default = "catalogue"
}

# ---------------------------------------------------------------------------
# rule_priority
# ---------------------------------------------------------------------------
# This variable defines the default listener rule priority in the ALB.
# ALB listener rules are evaluated based on priority — lower numbers are evaluated first.
# Each service (catalogue, cart, user, etc.) gets a unique priority value to avoid conflicts.
# ---------------------------------------------------------------------------
variable "rule_priority" {
  default = 10
}


# ---------------------------------------------------------------------------
# components (map of objects)
# ---------------------------------------------------------------------------
# This variable defines a map of all Roboshop components and their respective rule priorities.
# It allows centralized management of listener rule priorities across multiple services.
#
# Key  → Component name
# Value → Object containing configuration details like rule_priority
#
# You can use this map to dynamically fetch each component's ALB listener rule priority.
# Example:
#   var.components["catalogue"].rule_priority → returns 10
#   var.components["cart"].rule_priority      → returns 30
#
# This structure helps prevent hardcoding priorities in multiple places.
# ---------------------------------------------------------------------------

variable "components" {
  default = {
    catalogue = {
      rule_priority = 10
    }
    user = {
      rule_priority = 20
    }
    cart = {
      rule_priority = 30
    }
    shipping = {
      rule_priority = 40
    }
    payment = {
      rule_priority = 50
    }
    frontend = {
      rule_priority = 10
    }
  }
}
