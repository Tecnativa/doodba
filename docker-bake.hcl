variable "IMAGE_NAME" {
  default = "tecnativa/doodba"
}
variable "VERSIONS" {
  default = ["11.0", "12.0", "13.0","14.0","15.0","16.0","17.0","18.0","19.0"]
}
variable "SUFFIX" {
 default = ""
}
variable "VARIANTS" {
  default = ["base", "onbuild"]
}
variable "CI_SKIP_VERSIONS" {
    default = ["11.0","12.0"]
}
group "default" {
  targets = [
    "onbuild-${ODOO_VERSION}",
    "base-${ODOO_VERSION}"
  ]
}
variable "ODOO_VERSION" {
    default = replace(VERSIONS[length(VERSIONS) - 1], ".0", "")
}
variable "PLATFORMS" {
    default = ""
}
group "all" {
  targets = flatten([
    for version in VERSIONS : [
      for variant in VARIANTS :
        "${variant}-${replace(version, ".0", "")}"
    ]
  ])
}

group "ci" {
  targets = flatten([
    for version in setsubtract(VERSIONS, CI_SKIP_VERSIONS) : [
      for variant in VARIANTS :
        "${variant}-${replace(version, ".0", "")}"
    ]
  ])
}
target "doodba" {
  matrix = {
    version = VERSIONS
    variant = ["base", "onbuild"]
  }
  name = "${variant}-${replace(version, ".0", "")}"
  tags = [
    "${IMAGE_NAME}:${version}-${variant}${SUFFIX}"
  ]
  context = "."
  dockerfile = "${version}.Dockerfile"
  platforms = split(",", PLATFORMS)
}
