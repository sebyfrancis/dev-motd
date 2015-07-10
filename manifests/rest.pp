# For REST-specific configs

class profiles::rest {
  $pkgsforfonts = ["cabextract", "fontconfig", "xorg-x11-font-utils", "xset",]

  package { $pkgsforfonts: ensure => present, }
  package { 'msttcore-fonts': ensure => absent, } ->
  package { 'msttcore-fonts-installer': ensure => present, }

  # So the JVM can 'see' the MS TTcore fonts.
  file { '/usr/share/fonts/truetype':
    ensure => link,
    target => '/usr/share/fonts/msttcore',
  }

  # Add MRPE check for TTS daemon:
  file_line { 'is_ivonacl_running':
    path  => '/etc/check_mk/mrpe.cfg',
    match => '^tts_process',
    line  => "tts_process /usr/lib64/nagios/plugins/check_procs -c 1: -a ivonacl",
  }

  # Add MRPE check to show REST EAR version:
  file_line { 'REST-EAR-ver':
    path  => '/etc/check_mk/mrpe.cfg',
    match => '^REST-EAR-ver',
    line  => "REST-EAR-ver /usr/lib64/nagios/plugins/check_file_exists /var/resin/autodeploy/*md5",
  }

  # Cron job to start up Ivona TTS
  cron { 'start-ivona-tts':
    command => '/opt/ivona-telecom-pc_linux-8khz-1.6.38.186-en_us_salli/bin/ivonacl -D',
    user    => root,
    special => 'reboot',
  }

  # Ivona vPBX license:
  # Modify the config file to point to the correct license filename
  # and upload license file
  file { 'Certificate_of_authenticity_VPBX_ivonacl_5ports.ca':
    ensure => file,
    path   => '/opt/ivona-telecom-pc_linux-8khz-1.6.38.186-en_us_salli/license/Certificate_of_authenticity_VPBX_ivonacl_5ports.ca',
    mode   => '644',
    source => 'puppet:///modules/profiles/ivona-licenses/Certificate_of_authenticity_VPBX_ivonacl_5ports.ca',
  } ->
  file_line { 'ivona-config-pbx-license':
    path  => '/opt/ivona-telecom-pc_linux-8khz-1.6.38.186-en_us_salli/etc/ivonacl.conf',
    match => '^certificate',
    line  => "certificate = /opt/ivona-telecom-pc_linux-8khz-1.6.38.186-en_us_salli/license/Certificate_of_authenticity_VPBX_ivonacl_5ports.ca",
  }

  # Logs for Logstash to read:
  $_redis_rr_dns_name  = hiera('redis_rr_dns_name')
  $_logstash_redis_key = hiera('logstash_redis_key')

  $logstashconf        = '
  input {
    file {
      type => "rest"
      path => [ "/var/log/resin/jvm*log", "/var/log/resin/watchdog*", "/var/log/resin/platform28.log" ]
      exclude => ["*.gz", "*.bz2"]
    }
  }

  filter {
    if [type] == "rest" {
      multiline {
        pattern => "^\s"
        what    => "previous"
      }

      grok {
        match => [ "message", "%{TIMESTAMP_ISO8601:logtimestamp}" ]
        add_tag => [ "grokdated", "grokked"]
      }
      date {
        match => [ "logtimestamp", "YYYY-MM-dd HH:mm:ss,SSS", "ISO8601" ]
        add_tag => [ "dated" ]
      }
    }
  }

  output {
    if [type] == "rest" {
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

  logstash::configfile { 'rest-logs':
    content => $logstashconf,
    order   => 30,
  }

}
