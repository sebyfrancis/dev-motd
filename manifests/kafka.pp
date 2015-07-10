# For installing and configuring Kafka

class profiles::kafka {
  $_zk_host_list = hiera('zk_hosts')

  # Install Kafka using custom-built RPM
  package { 'jdk': ensure => present, } ->
  package { 'apache-kafka': ensure => present, }

  file { '/opt/platform28/kafka/logs':
    ensure  => link,
    target  => '/var/log/kafka',
    require => Package['apache-kafka'],
  }

  service { 'kafka':
    enable  => true,
    ensure  => running,
    require => Package['apache-kafka']
  }

  # Kafka's server.properties config file
  file { "/opt/platform28/kafka/config/server.properties":
    ensure  => present,
    owner   => 'kafka',
    group   => 'kafka',
    mode    => '644',
    content => template('profiles/kafka/server.properties.erb'),
    require => Package['apache-kafka'],
    notify  => Service['kafka'],
  }

  file { "/opt/platform28/kafka/config/log4j.properties":
    ensure  => present,
    owner   => 'kafka',
    group   => 'kafka',
    mode    => '644',
    source  => 'puppet:///modules/profiles/kafka/log4j.properties',
    require => Package['apache-kafka'],
    notify  => Service['kafka'],
  }

  file { "/etc/cron.daily/delete-old-kafka-logs.sh":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '755',
    source  => 'puppet:///modules/profiles/kafka/delete-old-kafka-logs.sh',
    require => Package['apache-kafka'],
  }
}
