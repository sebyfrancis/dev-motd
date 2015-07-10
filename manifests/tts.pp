# For Text-to-Speech (TTS) Converter Servers (MRCP):

class profiles::tts {
  package { 'jre1.8.0_25-1.8.0_25-fcs': ensure => present, }

  # Install Ivona MRCP server:
  exec { 'get-mrcp-installer-file':
    path    => ['/usr/bin', '/usr/sbin', '/bin', '/sbin'],
    command => 'wget -q http://repo.platform28.com/apps/ivona-telecom_mrcp-pc_linux-8khz-1.6.38.186-en_us_salli.bin -O /tmp/ivona-telecom_mrcp-pc_linux-8khz-1.6.38.186-en_us_salli.bin',
    creates => '/tmp/ivona-telecom_mrcp-pc_linux-8khz-1.6.38.186-en_us_salli.bin',
    timeout => 0,
  } ->
  file { '/tmp/ivona-telecom_mrcp-pc_linux-8khz-1.6.38.186-en_us_salli.bin': mode => '755', } ->
  exec { 'ivona-non-interactive-install':
    path    => ['/usr/bin', '/usr/sbin', '/bin', '/sbin'],
    command => '/tmp/ivona-telecom_mrcp-pc_linux-8khz-1.6.38.186-en_us_salli.bin -a -p /opt/ivona-telecom_mrcp-pc_linux-8khz-1.6.38.186-en_us_salli',
    # don't run this exec if this dir already exists, since the installer creates it:
    creates => '/opt/ivona-telecom_mrcp-pc_linux-8khz-1.6.38.186-en_us_salli',
    timeout => 0,
  } ->
  file { 'license-dir':
    ensure => directory,
    path   => '/opt/ivona-telecom_mrcp-pc_linux-8khz-1.6.38.186-en_us_salli/license',
    mode   => '755',
  }

  # Cron job to start up Ivona MRCP server:
  cron { 'start-ivona-mrcp':
    command => '/opt/ivona-telecom_mrcp-pc_linux-8khz-1.6.38.186-en_us_salli/bin/ivona_mrcp start 2>&1 > /var/log/messages',
    user    => root,
    special => 'reboot',
  }

  # delete old Ivona log files:
  cron { 'delete-old-ivona-log-files':
    environment => ['MAILTO=""', 'PATH=/bin:/usr/bin:/usr/sbin:/usr/local/bin'],
    command     => 'find /opt/ivona-telecom_mrcp-pc_linux-8khz-1.6.38.186-en_us_salli/  -name \*.log.\* -mtime +14 -exec rm {} \;',
    user        => root,
    minute      => '0',
    hour        => '6',
  }

  # Add MRPE check for TTS daemon:
  file_line { 'is_ivonacl_running':
    path  => '/etc/check_mk/mrpe.cfg',
    match => '^tts_process',
    line  => "tts_process /usr/lib64/nagios/plugins/check_procs -c 1: -a ivonacl",
  }

  # Ivona MRCP license:
  # Modify the config file to point to the correct license filename
  # and upload license file
  file { 'Certificate_of_authenticity_IVR_MRCP_10ports.ca':
    require => Exec['get-mrcp-installer-file'],
    ensure  => file,
    path    => '/opt/ivona-telecom_mrcp-pc_linux-8khz-1.6.38.186-en_us_salli/license/Certificate_of_authenticity_IVR_MRCP_10ports.ca',
    mode    => '644',
    source  => 'puppet:///modules/profiles/ivona-licenses/Certificate_of_authenticity_IVR_MRCP_10ports.ca',
  } ->
  file_line { 'ivona-config-mrcp-license':
    path  => '/opt/ivona-telecom_mrcp-pc_linux-8khz-1.6.38.186-en_us_salli/etc/ivonacl.conf',
    match => 'certificate',
    line  => "certificate = /opt/ivona-telecom_mrcp-pc_linux-8khz-1.6.38.186-en_us_salli/license/Certificate_of_authenticity_IVR_MRCP_10ports.ca",
  }

  # Logstash config for Ivona server
  $_redis_rr_dns_name  = hiera('redis_rr_dns_name')
  $_logstash_redis_key = hiera('logstash_redis_key')

  file { '/etc/logstash/patterns/ivona-timestamp':
    ensure  => present,
    content => "TIMESTAMP_IVONA %{MONTHDAY} %{MONTH} %{YEAR} %{HOUR}:?%{MINUTE}(?::?%{SECOND})",
  }

  $logstashconf = '
  input {
    file {
      type => "tts"
      path => [ "/opt/ivona-telecom_mrcp-pc_linux-8khz-1.6.38.186-en_us_salli/ivona_mrcp.log" ]
      exclude => ["*.gz", "*.bz2"]
    }
  }

  filter {
      grok {
        patterns_dir => "/etc/logstash/patterns"
        match => [ "message", "%{TIMESTAMP_IVONA:logtimestamp}" ]
        add_tag => [ "grokdated", "grokked"]
      }
      date {
        match => [ "logtimestamp", "dd MMM YYYY HH:mm:ss", "ISO8601" ]
        add_tag => [ "dated" ]
      }
  }

  output {
    if [type] == "tts" {
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

  logstash::configfile { 'ivona-tts-logs':
    content => $logstashconf,
    order   => 30,
  }

}
