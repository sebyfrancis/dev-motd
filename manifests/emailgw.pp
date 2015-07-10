# For email gateways

class profiles::emailgw {
  $_email_app_key             = hiera('email_app_key')
  $_app_server                = hiera('app_server')
  $_acd_server                = hiera('acd_server')
  $_route_server              = hiera('route_server')
  $_sip_registration_domain   = hiera('sip_registration_domain')
  $_sip_registration_username = hiera('sip_registration_username')
  $_sip_registration_password = hiera('sip_registration_password')
  $_sip_proxy_server          = hiera('sip_proxy_server')
  $_jdbc_url                  = hiera('jdbc_url')
  $_db_username               = hiera('db_username')
  $_db_password               = hiera('db_password')
  $_zk_hosts_and_ports        = hiera('zk_hosts_and_ports')
  $_kafka_hosts_and_ports     = hiera('kafka_hosts_and_ports')

  package { 'jdk': ensure => present, } ->
  package { 'resin-pro': ensure => present, } ->
  package { 'resin-extra-jars': ensure => present, }

  file { ['/var/resin/deploy', '/var/resin/autodeploy']:
    ensure  => "directory",
    owner   => "resin",
    group   => "resin",
    mode    => "775",
    require => Package['resin-pro'],
  }

  # resin.xml
  file { "/etc/resin/resin.xml":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '644',
    content => template('profiles/emailgw/resin.xml.erb'),
    require => Package['resin-pro'],
    notify  => File_line['resin_jvm_args'],
  }

  # resin.properties
  file { "/etc/resin/resin.properties":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '644',
    content => template('profiles/emailgw/resin.properties.erb'),
    require => Package['resin-pro'],
    notify  => File_line['resin_jvm_args'],
  }

  # resin license
  file { "/etc/resin/licenses/1016003.license":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '644',
    source  => 'puppet:///modules/profiles/emailgw/1016003.license',
    require => Package['resin-pro'],
    notify  => File_line['resin_jvm_args'],
  }

  $freemem = $::memorysize_mb - 1000
  $jvm_xmx = floor($freemem)

  file_line { 'resin_jvm_args':
    path  => '/etc/resin/resin.properties',
    match => '^jvm_args',
    line  => "jvm_args : -Xms${jvm_xmx}m -Xmx${jvm_xmx}m -XX:MaxPermSize=512m -Djava.net.preferIPv4Stack=true -javaagent:/opt/newrelic/newrelic.jar",
  # notify  => Exec['restart'],
  }

  service { 'resin':
    ensure => running,
    enable => true,
  }

  file { '/etc/sudoers.d/resin':
    ensure  => file,
    require => Package['resin-pro'],
    content => "resin ALL = NOPASSWD: /sbin/service, /bin/logger \n",
  }

  user { 'resin':
    shell    => '/bin/bash',
    password => '$1$S568sYNp$Jlt0/EANj1QhBtCjj6Hpg.'
  }

  file { 'delete-old-resin-logs':
    path    => '/etc/cron.daily/delete-old-resin-logs',
    ensure  => file,
    mode    => 'u+x',
    require => Package['resin-pro'],
    source  => 'puppet:///modules/profiles/emailgw/delete-old-resin-logs',
  }

  # New Relic install and configuration:
  # $newrelic_appname = upcase($role)
  # $newrelic_svrname = "$role$instance"

  # file { 'newrelic':
  #   path    => '/opt/newrelic',
  #   ensure  => directory,
  #   mode    => 'u+x',
  #   owner   => 'resin',
  #   group   => 'resin',
  #   recurse => true,
  #   source  => 'puppet:///modules/resin/newrelic',
  #   require => Package['resin-pro'],
  #}

  # file { '/opt/newrelic/newrelic.yml':
  #   require => File['newrelic'],
  #   content => template('resin/newrelic.yml.erb'),
  #}

  # hibernate.cfg.xml
  file { "/usr/local/share/resin/lib/hibernate.cfg.xml":
    ensure  => file,
    owner   => 'resin',
    group   => 'resin',
    mode    => '0644',
    source  => 'puppet:///modules/profiles/emailgw/hibernate.cfg.xml',
    require => Package['resin-pro'],
  #    notify  => Exec['restart'],
  }

  file { '/usr/local/share/resin/lib/log4j.properties':
    ensure  => present,
    mode    => '644',
    owner   => 'resin',
    source  => 'puppet:///modules/profiles/emailgw/log4j.properties',
    require => Package['resin-pro'],
  }

  file { '/var/log/resin/':
    ensure => directory,
    mode   => '755',
    owner  => 'resin',
    group  => 'resin',
  } ->
  file { '/var/log/resin/emailgw.log':
    ensure => file,
    mode   => '644',
    owner  => 'resin',
    group  => 'resin',
  }

  # New Relic install and configuration:
  $newrelic_appname = upcase($role)
  $newrelic_svrname = "$role$instance"

  file { 'newrelic':
    path    => '/opt/newrelic',
    ensure  => directory,
    mode    => 'u+x',
    owner   => 'resin',
    group   => 'resin',
    recurse => true,
    source  => 'puppet:///modules/resin/newrelic',
    require => Package['resin-pro'],
  }

  file { '/opt/newrelic/newrelic.yml':
    require => File['newrelic'],
    content => template('resin/newrelic.yml.erb'),
  }

  # Logstash config for Email gateway app
  $_redis_rr_dns_name  = hiera('redis_rr_dns_name')
  $_logstash_redis_key = hiera('logstash_redis_key')

  $logstashconf        = '
  input {
    file {
      type => "email"
      path => [ "/home/emailgateway/log/jvm*log", "/home/emailgateway/log/access.log", "/home/emailgateway/log/watchdog-manager.log" ]
      exclude => ["*.gz", "*.bz2"]
    }
  }

  filter {
    if [type] == "email" {
      multiline {
        pattern => "^\s"
        what    => "previous"
      }

      grok {
        match => [ "message", "%{TIMESTAMP_ISO8601:logtimestamp}" ]
        add_tag => [ "grokdated", "grokked"]
      }
      date {
        match => [ "logtimestamp", "YYYY-MM-dd HH:mm:ss,SSS", "YYYY-MM-dd HH:mm:ss.SSS", "ISO8601" ]
        add_tag => [ "dated" ]
      }
    }
  }

  output {

    if "Another checker is in progress" in [message] {
      #stdout { codec => rubydebug }
      email {
        from => "logstash.alert@emailgw2.aws1.platform28.com"
        subject => "ALERT! Email gateway may have stopped checking email "
        to => "noc+emailgw2@platform28.com, staci@platform28.com"
        via => "smtp"
        body => "Ask Ops to look at logs and possibly restart the email gateway. Here is the log entry: \n %{message}"
      }
      file {
        path => "/tmp/email.debug.log"
      }
    }

    if [type] == "email" {
      redis {
        # hardcoded. future: update $logstashconf to use double-quotes, then drop in Hiera vars
        # or better yet, turn this into a template.
        host      => "redis.aws1.platform28.com"
        data_type => "list"
        key       => "logstashbaby"
      }
    }
  }
'

  logstash::configfile { 'emailgw-logs':
    content => $logstashconf,
    order   => 30,
  }

}
