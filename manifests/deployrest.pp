# For deploying the REST EARs

class profiles::deployrest {
  # ONLY put the REST EAR into this var
  $rest_ear_name = 'j2ee-rest-api-app-2015-W26.ear'

  file { 'deployear.sh':
    path    => '/var/resin/deployear.sh',
    ensure  => file,
    owner   => 'resin',
    group   => 'resin',
    mode    => '775',
    require => Package['resin-pro'],
    source  => 'puppet:///modules/resin/deployear.sh',
  }

  exec { 'deployrest':
    require   => File['deployear.sh'],
    command   => "/var/resin/deployear.sh $rest_ear_name",
    user      => 'resin',
    logoutput => 'on_failure',
    timeout   => 1800,
  }
}
