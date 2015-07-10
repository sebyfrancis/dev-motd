# For installing and configuring Zookeeper (ZK)

class profiles::zookeeper {
  $_zk_hosts = hiera('zk_hosts')

  # Install Zookeeper using custom-built RPM
  package { 'jdk': ensure => present, } ->
  package { 'apache-zookeeper': ensure => present, }

  file { '/opt/platform28/zookeeper/logs':
    ensure  => link,
    target  => '/var/log/zookeeper',
    require => Package['apache-zookeeper'],
  }

  service { 'zookeeper':
    enable  => true,
    ensure  => running,
    require => Package['apache-zookeeper']
  }

  # Zookeeper's main config file
  file { "/opt/platform28/zookeeper/conf/zoo.cfg":
    ensure  => present,
    owner   => 'zk',
    group   => 'zk',
    mode    => '644',
    content => template('profiles/zookeeper/zoo.cfg.erb'),
    require => Package['apache-zookeeper'],
    notify  => Service['zookeeper'],
  }

  file { "/var/zookeeper/data/myid":
    ensure  => present,
    owner   => 'zk',
    group   => 'zk',
    mode    => '644',
    content => template('profiles/zookeeper/myid.erb'),
    require => Package['apache-zookeeper'],
    notify  => Service['zookeeper'],
  }
}
