# Class: odaiZabbixProxy
#
# This module manages odaiZabbix
#
# Parameters: none
#
# Actions:
#
# Requires: see Modulefile
#
# Sample Usage:
#
class odaizabbixproxy ($zabbix_server, $version = '2.2.1') {
  if !($version in ['2.2.1','2.2.2']) {
    fail("\"${version}\" is not a supported version value")
  }

  # first install MySQL

  class { 'mysql::server':
    config_hash => {
      root_password => hiera('mysqlrootzabbixproxypwd', ""),
      bind_address  => $::ipaddress,
    }
  }

  $dbname = 'zabbix'
  $dbuser = 'zabbix'
  $dbpassword = hiera('mysqlzabbixproxypwd', "")

  # now install the zabbix-proxy

  package { 'zabbix-proxy-mysql':
    ensure  => present,
    require => Class["mysql::server"]
  }

  package { 'zabbix-java-gateway':
    ensure  => present,
    require => Package["zabbix-proxy-mysql"],
  }
  
  mysql::db { "$dbname":
    user     => $dbuser,
    password => $dbpassword,
    host     => $::fqdn,
    grant    => ['all'],
    sql      => "/usr/share/doc/zabbix-proxy-mysql-${version}/create/schema.sql",
    require  => Package["zabbix-proxy-mysql"],
  }


  # modify zabbix_proxy.conf
  file { "/etc/zabbix/zabbix_proxy.conf":
    content => template("odaizabbixproxy/${version}/zabbix_proxy.conf.erb"),
    owner   => 'root',
    group   => 'zabbix',
    mode    => 0644,
    require => Package["zabbix-java-gateway"],
  }

  service { 'zabbix-proxy':
    ensure  => 'running',
    require => [File['/etc/zabbix/zabbix_proxy.conf'], Mysql::Db["$dbname"]]
  }
}
