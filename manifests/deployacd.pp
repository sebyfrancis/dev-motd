# For deploying the ACD EARs

class profiles::deployacd {
  # ONLY put the ACD EAR into this var
  $ear_name = 'j2ee-acd-app-2015-02-23-W08-2.ear'

  file { 'deployear.sh':
    path    => '/var/resin/deployear.sh',
    ensure  => file,
    owner   => 'resin',
    group   => 'resin',
    mode    => '775',
    require => Package['resin-pro'],
    source  => 'puppet:///modules/resin/deployear.sh',
  }

  exec { 'deployacd':
    require   => File['deployear.sh'],
    command   => "/var/resin/deployear.sh $ear_name",
    user      => 'resin',
    logoutput => 'on_failure',
    timeout   => 1800,
  }
}
