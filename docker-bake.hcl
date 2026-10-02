variable "IMAGE_NAME" {
    default = "tecnativa/doodba"
}
variable "VERSIONS" {
    type = list(string)
    default = ["11.0", "12.0", "13.0","14.0","15.0","16.0","17.0","18.0","19.0","20.0"]
}
variable "TAG_SUFFIX" {
    default = ""
}
variable "VARIANTS" {
    default = [{"target":"base", "tag":""}, {"target": "onbuild", "tag":"-onbuild"}]
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
variable "REGISTRIES" {
    default = ["ghcr.io","docker.io"]
}
group "all" {
    targets = flatten([
    for version in VERSIONS : [
      for variant in VARIANTS :
        "${variant.target}-${replace(version, ".0", "")}"
    ]
  ])
}

group "ci" {
    targets = flatten([
    for version in setsubtract(VERSIONS, CI_SKIP_VERSIONS) : [
      for variant in VARIANTS :
        "${variant.target}-${replace(version, ".0", "")}"
    ]
  ])
}
target "doodba" {
    matrix = {
        version = VERSIONS
        variant = VARIANTS
    }
    name = "${variant.target}-${replace(version, ".0", "")}"
    tags = [
    for registry in REGISTRIES :
        "${registry}/${IMAGE_NAME}:${version}${variant.tag}${TAG_SUFFIX}"
    ]
    target = variant.target
    context = "."
    dockerfile = "${version}.Dockerfile"
    platforms = split(",", PLATFORMS)
}
