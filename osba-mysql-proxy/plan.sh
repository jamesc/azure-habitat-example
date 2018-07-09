pkg_name=osba-mysql-proxy
pkg_origin=azure-habitat-example
pkg_version="0.1.1"
pkg_maintainer="The Habitat Maintainers <humans@habitat.sh>"
pkg_license=("Apache-2.0")
pkg_description="A Proxy Service for MySQL service created via Open Service Broker for Azure (OSBA)"

pkg_deps=(
    core/busybox-static
    core/curl
    core/jq-static
)

pkg_exports=(
  [host]=mysql.host
  [port]=mysql.port
  [username]=mysql.username
  [database]=mysql.database
  [password]=mysql.password
  [uri]=mysql.uri
)

do_build() {
    return 0
}

do_install() {
    return 0
}
