# For installing and configuring Statsgen (the Statistics Generator)

class profiles::statsgen {
  $_statsgen_zk_hosts          = hiera('statsgen_zk_hosts')
  $_statistics_db_url          = hiera('statistics_db_url')
  $_statistics_db_username     = hiera('statistics_db_username')
  $_statistics_db_password     = hiera('statistics_db_password')
  $_hazelcast_local_configFile = hiera('hazelcast_local_configFile')

  # Add MRPE check for Statsgen process:
  file_line { 'is_statsgen_running':
    path  => '/etc/check_mk/mrpe.cfg',
    match => '^statsgen_process',
    line  => "statsgen_process /usr/lib64/nagios/plugins/check_procs -c 1: -a statsgen",
  }

  # MRPE check of Statsgen process' CPU:
  file_line { 'statsgen_process_cpu':
    path  => '/etc/check_mk/mrpe.cfg',
    match => '^statsgen_process_cpu',
    line  => "statsgen_process_cpu /usr/lib64/nagios/plugins/check_proc_cpu.sh -w 40 -c 50 --cmdpattern infinispan",
  }

  group { 'statsgen': ensure => present, }

  user { 'statsgen':
    ensure  => present,
    comment => 'Platform28 Statistics Generator',
    home    => '/home/statsgen',
    shell   => '/bin/bash',
    groups  => 'statsgen',
  }

  package { 'statsgen-openejb':
    ensure  => present,
    require => User['statsgen'],
  }

  file { "openejb.xml":
    ensure  => present,
    require => Package['statsgen-openejb'],
    path    => '/home/statsgen/apache-openejb/conf/openejb.xml',
    mode    => '644',
    owner   => 'statsgen',
    group   => 'statsgen',
    content => template('profiles/statsgen/openejb.xml.erb'),
  }

  file { "system.properties":
    ensure  => present,
    require => Package['statsgen-openejb'],
    path    => '/home/statsgen/apache-openejb/conf/system.properties',
    mode    => '644',
    owner   => 'statsgen',
    group   => 'statsgen',
    content => template('profiles/statsgen/system.properties.erb'),
  }

  # Set up an automatic start on boot out of cron:
  cron { 'start-statsgen-on-boot':
    command => '/home/statsgen/start_statsgen.sh',
    user    => 'statsgen',
    special => 'reboot',
  }

  # Logs for Logstash to process:
  $logstashconf = 'input {
    file {
      type => "statsgen"
      path => [ "/var/log/statsgen/statsgen.log" ]
    }
  }'

  logstash::configfile { 'Statsgen-logs':
    content => $logstashconf,
    order   => 30,
  }
}
