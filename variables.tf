variable "location" {
  description = "Région Azure"
  type        = string
  default     = "canadacentral"
}

variable "prefix" {
  description = "Préfixe pour nommer les ressources"
  type        = string
  default     = "cr460"
}

variable "vm_size" {
  description = "Taille de la VM"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Utilisateur administrateur de la VM"
  type        = string
  default     = "azureadmin"
}

variable "project_tag" {
  description = "Valeur du tag de gestion des coûts"
  type        = string
  default     = "DevoirCR460"
}