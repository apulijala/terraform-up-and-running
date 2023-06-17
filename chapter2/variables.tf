variable "object_example" {
  type = object(
    {
    name = string
    age = number
    tags = list(string)
    enabled = bool

  }
  )

  default = {
    name = "arvind"
    age = 21
    tags = ["a", "b", "c"]
    enabled = true
  }
}

variable "server_port" {
  type = number
  default = 8080
}

