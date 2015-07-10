# For installing and configuring the Outbound Dialer

class profiles::dialer {
  $_dialer_db_url           = hiera('dialer_db_url')
  $_dialer_db_username      = hiera('dialer_db_username')
  $_dialer_db_password      = hiera('dialer_db_password')
  $_dialer_app_key          = hiera('dialer_app_key')
  $_api_server              = hiera('api_server')
  $_sip_registration_domain = hiera('sip_registration_domain')
  $_sip_bind_address        = hiera('sip_bind_address')

  # Create user and group in case RPM doesn't
  group { 'dialer': ensure => present, }

  user { 'dialer':
    ensure  => present,
    comment => 'Platform28 Outbound Dialer',
    home    => '/opt/platform28/dialer/',
    shell   => '/bin/bash',
    groups  => 'dialer',
  }

  package { 'outbound-dialer':
    ensure  => latest,
    require => User['dialer'],
  }

}

