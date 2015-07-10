# For installing and configuring FSES (FreeSWITCH Event Socket app)

class profiles::fses {
  # NOTE that this is now uninstalling everything below:

  exec { 'killfsesprocs': command => "/usr/bin/pkill -KILL -u fses 2>/dev/null; echo 0", }

  package { 'fses': ensure => absent, }

  package { 'fses-app': ensure => absent, }

  cron { 'restart-fses':
    ensure  => absent,
    user    => 'root',
    minute  => "*/1",
    command => '/opt/platform28/fses/bin/restart-fses-openejb.sh',
  }

  # Create user and group in case RPM doesn't
  user { 'fses':
    ensure  => absent,
    comment => 'FreeSWITCH Event Socket server (FSES)',
    home    => '/opt/platform28/fses/',
    shell   => '/bin/bash',
    groups  => 'freeswitch',
    require => Exec['killfsesprocs'],
  } ->
  group { 'fses':
    ensure  => absent,
    members => 'fses',
    require => Exec['killfsesprocs'],
  }

  #  file { '/etc/freeswitch/directory':
  #    require => File['/etc/freeswitch'],
  #    recurse => true,
  #    owner   => 'fses',
  #    mode    => 'ugo+x',
  #  }
}
