# For installing and configuring OpenSIPS

class profiles::opensips {
  yumrepo { 'opensips':
    baseurl  => 'http://yum.opensips.org/1.10/releases/el/$releasever/$basearch/',
    descr    => 'OpenSIPS and related RPMs',
    enabled  => 1,
    priority => '50',
    gpgcheck => 0,
  }

  $opensipspkgs = [
    'opensips-pua',
    'opensips-presence_xml',
    'opensips-acc',
    'opensips-xcap',
    'opensips-presence',
    'opensips-pua_dialoginfo',
    'opensips-mysql',
    'opensips-memcached',
    'opensips-json',
    'opensips-xcap_client',
    'opensips-pua_usrloc',
    'opensips-regex',
    ]

  package { $opensipspkgs:
    require => Yumrepo['opensips'],
    ensure  => present,
  }

  package { 'opensips':
    ensure  => present,
    require => Yumrepo['opensips'],
  }

  service { 'opensips':
    enable  => true,
    ensure  => running,
    require => Package['opensips']
  }

  package { 'rtpproxy':
    ensure  => present,
    require => Yumrepo['opensips'],
  }

  service { 'rtpproxy':
    enable  => true,
    ensure  => running,
    require => Package['rtpproxy']
  }

  class { 'ulimit':
    purge => false,
  }

  ulimit::rule { 'rtpproxy':
    ulimit_domain => '*',
    ulimit_type   => 'soft',
    ulimit_item   => 'nofile',
    ulimit_value  => '32000',
  }

  ulimit::rule { 'opensips1':
    ulimit_domain => '*',
    ulimit_type   => '-',
    ulimit_item   => 'nofile',
    ulimit_value  => '99999',
  }

  ulimit::rule { 'opensips2':
    ulimit_domain => '*',
    ulimit_type   => '-',
    ulimit_item   => 'memlock',
    ulimit_value  => 'unlimited',
  }

  ulimit::rule { 'opensips3':
    ulimit_domain => '*',
    ulimit_type   => '-',
    ulimit_item   => 'msgqueue',
    ulimit_value  => 'unlimited',
  }

  ulimit::rule { 'opensips4':
    ulimit_domain => '*',
    ulimit_type   => '-',
    ulimit_item   => 'nproc',
    ulimit_value  => 'unlimited',
  }

  ulimit::rule { 'opensips5':
    ulimit_domain => '*',
    ulimit_type   => '-',
    ulimit_item   => 'sigpending',
    ulimit_value  => 'unlimited',
  }

  ulimit::rule { 'opensips6':
    ulimit_domain => '*',
    ulimit_type   => 'soft',
    ulimit_item   => 'core',
    ulimit_value  => 'unlimited',
  }

  notify { 'configreminder': message => "Remember to edit opensips.cfg and rtpproxy config depending on public/private IP addresses.", 
  }

  file { "/etc/opensips/opensips.cfg":
    ensure  => present,
    owner   => 'opensips',
    group   => 'opensips',
    mode    => '644',
    source  => 'puppet:///modules/profiles/opensips.cfg',
    ignore  => '.git',
    require => Package['opensips'],
    notify  => Service['opensips'],
  }

  file { "/etc/sysconfig/rtpproxy":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '644',
    source  => 'puppet:///modules/profiles/sysconfig-rtpproxy',
    ignore  => '.git',
    require => Package['rtpproxy'],
    notify  => Service['rtpproxy'],
  }

  file { "/usr/bin/rtpproxy":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '755',
    source  => 'puppet:///modules/profiles/rtpproxy-bin',
    ignore  => '.git',
    require => Package['rtpproxy'],
    notify  => Service['rtpproxy'],
  }

  file_line { 'opensips-info':
    path   => '/etc/rsyslog.conf',
    match  => '^\*.info',
    line   => "*.info;mail.none;authpriv.none;cron.none;local3.none;local2.none    /var/log/messages",
    notify => Service['rsyslog']
  }

  file_line { 'rsyslog-opensips-log':
    path   => '/etc/rsyslog.conf',
    match  => '^local3.\*',
    line   => "local3.*  /var/log/opensips/opensips.log",
    notify => Service['rsyslog']
  }

  file_line { 'rsyslog-rtpproxy-log':
    path   => '/etc/rsyslog.conf',
    match  => '^local2.\*',
    line   => "local2.*  /var/log/opensips/rtpproxy.log",
    notify => Service['rsyslog']
  }

  service { 'rsyslog':
    ensure => 'running',
    enable => 'true',
  }

  # Logs for Logstash to process:
  $logstashconf = 'input {
    file {
      type => "opensips"
      path => [ "/var/log/opensips/opensips.log" ]
    }
    file {
      type => "opensips"
      path => [ "/var/log/opensips/rtpproxy.log" ]
    }
  }
  filter {
    if [type] == "opensips" {
      grok {
        match => [ "message", "%{SYSLOGTIMESTAMP:logtimestamp}" ]
        add_tag => [ "grokdated", "grokked"]
      }
    }
  }'

  logstash::configfile { 'OpenSIPS-logs':
    content => $logstashconf,
    order   => 30,
  }

  package { 'mysqlproxy': ensure => absent, }
}
