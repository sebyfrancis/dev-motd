# For installing and configuring FreeSWITCH & TRADE
# (both of which are on the same server(s))

class profiles::freeswitch {
  #
  # FreeSWITCH application
  #
  yumrepo { 'freeswitch':
    baseurl  => 'http://files.freeswitch.org/yum/$releasever/$basearch/',
    descr    => 'FreeSWITCH and related RPMs',
    enabled  => 1,
    priority => '50',
    gpgcheck => 0,
  }

  package { 'freeswitch':
    ensure  => '1.5.16-1.el6',
    require => Yumrepo['freeswitch'],
  }

  $fspkgs = [
    'expat-devel',
    'freeswitch-asrtts-unimrcp',
    'freeswitch-xml-cdr',
    'freeswitch-perl',
    'freeswitch-python',
    'freeswitch-lua',
    'freeswitch-format-mod-shout',
    'freeswitch-asrtts-flite',
    'freeswitch-config-vanilla',
    'gcc',
    'libcurl-devel',
    'libjpeg-devel',
    'libogg-devel',
    'libtiff-devel',
    'libvorbis-devel',
    'lua-devel',
    'make',
    'openssl-devel',
    'pcre',
    'pcre-devel',
    'python-devel',
    'sox',
    'speex-devel',
    'sqlite-devel',
    'unixODBC-devel',
    'unzip',
    'zlib',
    'zlib-devel',
    ]
  package { $fspkgs:
    require => Yumrepo['freeswitch'],
    ensure  => present,
  } ->
  package { 'luarocks': ensure => present, }

  exec { 'fssoundspkgs':
    require => Yumrepo['freeswitch'],
    command => "/usr/bin/yum -y install freeswitch-sounds*",
    timeout => 1800,
  }

  file { '/etc/freeswitch':
    require => Package['freeswitch'],
    recurse => true,
    owner   => 'freeswitch',
    group   => 'freeswitch',
    mode    => 'g+w',
  }

  service { 'freeswitch':
    enable  => true,
    ensure  => running,
    require => Package['freeswitch'],
  }

  file { '/usr/share/freeswitch':
    owner   => 'freeswitch',
    group   => 'freeswitch',
    recurse => true,
    require => Package['freeswitch'],
  }

  file { '/usr/storage/':
    ensure  => directory,
    owner   => 'freeswitch',
    group   => 'freeswitch',
    mode    => 'g+ws',
    require => Package['freeswitch'],
  }

  exec { 'luarock-cjson':
    command => "/usr/bin/luarocks install lua-cjson",
    require => Package['luarocks'],
  }

  exec { 'luarock-mimetypes':
    command => '/usr/bin/luarocks install mimetypes',
    require => Package['luarocks'],
  }

  exec { 'luarock-socket':
    command => '/usr/bin/luarocks install luasocket',
    require => Package['luarocks'],
  }

  exec { 'luarock-pcre':
    command => '/usr/bin/luarocks install lrexlib-pcre PCRE_LIBDIR=/usr/lib64 2.7.2-1',
    require => Package['luarocks'],
  }

  class { 'ulimit':
    purge => false,
  }

  # delete old FreeSWITCH log files:
  cron { 'delete-old-freeswitch-log-files':
    command => 'find /var/log/freeswitch/  -name freeswitch.log\* -mtime +5 -exec rm {} \;',
    user    => root,
    hour    => '*/1',
    minute  => '6',
  }

  # Add MRPE check for FreeSWITCH process:
  file_line { 'is_freeswitch_running':
    path  => '/etc/check_mk/mrpe.cfg',
    match => '^freeswitch_process',
    line  => "freeswitch_process /usr/lib64/nagios/plugins/check_procs -c 1: -a freeswitch",
  }

  cron { 'num-of-fs-calls':
    command => 'fs_cli -pfr33sw1tch! -x "show calls count" |grep -v "^$" > /tmp/num-of-fs-calls.txt',
    user    => root,
    minute  => '*/5',
  }

  # Add MRPE check for # of FreeSWITCH calls:
  file_line { 'num_of_FS_calls':
    path  => '/etc/check_mk/mrpe.cfg',
    match => '^num_of_FS_calls',
    line  => "num_of_FS_calls /usr/lib64/nagios/plugins/check_file_exists /tmp/num-of-fs-calls.txt",
  }

  # FreeSWITCH configs, dialplans, etc.
  file { "/etc/freeswitch/dialplan/public/0000000000.xml":
    ensure => present,
    owner  => 'freeswitch',
    group  => 'freeswitch',
    mode   => '644',
    source => 'puppet:///modules/profiles/freeswitch/0000000000.xml',
  }

  file { '/var/log/freeswitch':
    ensure => directory,
    mode   => 'go+rx',
  }

  file_line { 'renice_freeswitch':
    path  => '/etc/rc.local',
    match => '^/usr/bin/renice',
    line  => "/usr/bin/renice -5 -p `pgrep -u freeswitch`",
  }

  #
  # TRADE application
  #

  # sync the TRADE bin and logs dirs to S3
  cron { 'sync-TRADE-logs':
    environment => ['MAILTO=""', 'PATH=/bin:/usr/bin:/usr/sbin:/usr/local/bin'],
    command     => 's3cmd  sync /home/tradekernel/TRADE/logs  s3://p28-trade-kernel-logs/`hostname -s`/  2>&1 >/dev/null',
    user        => root,
    minute      => '9',
    hour        => '*/1',
    ensure      => absent,
  }

  cron { 'sync-TRADE-bin':
    command => 's3cmd --rr sync /home/tradekernel/TRADE/bin  s3://p28-trade-kernel-logs/`hostname -s`/  2>&1 >/dev/null',
    user    => root,
    minute  => '*/30',
  }

  # delete old TRADE core files:
  cron { 'delete-old-trade-core-files':
    command => 'find /home/tradekernel/TRADE/bin  -name core.\* -mmin +720 -exec rm {} \;',
    user    => root,
    minute  => '*/20',
  }

  # compress old TRADE core files:
  cron { 'compress-old-trade-core-files':
    command => 'find /home/tradekernel/TRADE/bin  -name core.\* -mmin +20 -exec bzip2 {} \;',
    user    => root,
    minute  => '*/20',
  }

  # compress old TRADE log files:
  cron { 'compress-old-trade-log-files':
    command => 'find /home/tradekernel/TRADE/logs  -name EXSKernel-\*log\* -mmin +5 -exec bzip2 {} \;',
    user    => root,
    minute  => '*/10',
  }

  # delete old TRADE log files:
  cron { 'delete-old-trade-log-files':
    command => 'find /home/tradekernel/TRADE/logs  -name EXSKernel-\*log\* -mtime +3 -exec rm {} \;',
    user    => root,
    hour    => '*/1',
    minute  => '7',
  }

  # delete old recording_uploader log files:
  cron { 'delete-old-recording-uploader-log-files':
    command => 'find /home/tradekernel/TRADE/logs  -name recording_uploader.log.\* -mtime +2 -exec rm {} \;',
    user    => root,
    hour    => '*/1',
    minute  => '8',
  }

  # Restart recording-uploader daily:
  cron { 'restart-recording-uploader-daily':
    command => 'pkill -9 -u tradekernel -f recording-uploader',
    user    => root,
    hour    => '10',
    minute  => '0',
  }

  file { 's3cfg':
    path   => '/root/.s3cfg',
    ensure => file,
    mode   => '0400',
    source => 'puppet:///modules/profiles/fs-s3cfg',
  }

  file { 'static-route-for-stars':
    path   => '/etc/sysconfig/network-scripts/route-eth0',
    ensure => file,
    mode   => '644',
    source => 'puppet:///modules/profiles/fs-static-route-for-stars',
  }

  # Add MRPE check for P28Kernel process:
  file_line { 'is_p28kernel_running':
    path  => '/etc/check_mk/mrpe.cfg',
    match => '^p28kernel_process',
    line  => "p28kernel_process /usr/lib64/nagios/plugins/check_procs -c 1: -a p28kernel",
  }

  # Temp dir needed for local storage of recordings before push to S3 via REST call
  # Note that this requires the /media/ephemeral0 dir to be already mounted and does
  # not check for it
  file { '/media/ephemeral0/recordings/':
    ensure => directory,
    owner  => 'freeswitch',
    group  => 'freeswitch',
    mode   => '2777',
  }

  # Script to copy recordings from the temp dir up to S3 and then delete them
  file { '/usr/local/bin/migrate-recordings-to-s3.sh':
    ensure => file,
    mode   => '755',
    source => 'puppet:///modules/profiles/migrate-recordings-to-s3.sh',
  }

  # Execute the script above hourly
  cron { 'migrate-recordings-to-s3-cron':
    environment => ['MAILTO=""', 'PATH=/bin:/usr/bin:/usr/sbin:/usr/local/bin'],
    command     => '/usr/local/bin/migrate-recordings-to-s3.sh  2>&1 >/dev/null',
    user        => root,
    minute      => '45',
  }

  file { '/usr/local/bin/list-trade-core-files.sh':
    owner  => 'root',
    group  => 'root',
    mode   => 'u+x',
    source => 'puppet:///modules/profiles/list-trade-core-files.sh',
  }

  cron { 'list-trade-core-files':
    command => '/usr/local/bin/list-trade-core-files.sh',
    user    => root,
    minute  => '*/5',
    require => File['/usr/local/bin/list-trade-core-files.sh'],
  }

  # Add MRPE check for # of FreeSWITCH calls:
  file_line { 'list-trade-core-files':
    path  => '/etc/check_mk/mrpe.cfg',
    match => '^list-trade-core-files',
    line  => "list-trade-core-files /usr/lib64/nagios/plugins/check_file_exists /tmp/trade-core-files.txt",
  }

  # Temp dir needed for local storage of voicemail before push to REST server
  # Note that this requires the /media/ephemeral0 dir to be already mounted and does
  # not check for it
  file { '/media/ephemeral0/voicemail/':
    ensure => directory,
    owner  => 'freeswitch',
    group  => 'freeswitch',
    mode   => '2777',
  }

  file { '/usr/local/bin/list-trade-scl-files.sh':
    owner  => 'root',
    group  => 'root',
    mode   => 'u+x',
    source => 'puppet:///modules/profiles/list-trade-scl-files.sh',
  }

  cron { 'list-trade-scl-files':
    command => '/usr/local/bin/list-trade-scl-files.sh',
    user    => root,
    minute  => '*/5',
    require => File['/usr/local/bin/list-trade-scl-files.sh'],
  } # Add MRPE check for retrieving SCL file list:



  file_line { 'list-trade-scl-files':
    path  => '/etc/check_mk/mrpe.cfg',
    match => '^list-trade-scl-files',
    line  => "list-trade-scl-files /usr/lib64/nagios/plugins/check_file_exists /tmp/trade-scl-files.txt",
  }

  file { '/usr/local/bin/migrate-trade-logs-to-s3.sh':
    owner  => 'root',
    group  => 'root',
    mode   => 'u+x',
    source => 'puppet:///modules/profiles/migrate-trade-logs-to-s3.sh',
  }

  # Execute the script above hourly
  cron { 'migrate-logs-to-s3-cron':
    command => '/usr/local/bin/migrate-trade-logs-to-s3.sh  2>&1 >/dev/null',
    user    => root,
    minute  => '08',
  }

  user { 'renny':
    ensure     => present,
    comment    => 'Renny Koshy - temp account for debugging',
    groups     => 'daemon',
    shell      => '/bin/bash',
    home       => '/home/renny',
    managehome => true,
    password   => '$1$OyO.8v0R$FA2ou.rd34e3isuzb11NS1',
  }

  # Logstash shipper configs:
  # Note that this is for all components on this system.
  # If FreeSWITCH and TRADE are split up, this will also
  # need to be split up.
  $_redis_rr_dns_name  = hiera('redis_rr_dns_name')
  $_logstash_redis_key = hiera('logstash_redis_key')

  $logstashconf        = '
  input {
    file {
      type => "trade"
      path => [ "/home/tradekernel/TRADE/logs/EXSKernel.log" ]
    }
    file {
      type => "freeswitch"
      path => [ "/var/log/freeswitch/freeswitch.log" ]
    }
    file {
      type => "uploader"
      path => [ "/home/tradekernel/TRADE/logs/recording_uploader.log" ]
    }
    file {
      type => "uploader"
      path => [ "/home/tradekernel/TRADE/logs/voicemail_uploader.log" ]
    }
  }
  filter {
    if [type] == "trade" or [type] == "freeswitch" or [type] == "uploader" {
      # Note that the match format in the date filter has to match what is in the logs
      # TRADE log sample date format: 2015-06-25 19:11:58,970
      # FreeSWITCH log sample date format: 2015-06-25 19:15:14.701937
      # Uploader log sample date format: 2015-06-25 19:15:30,009
      grok {
        match => [ "message", "%{TIMESTAMP_ISO8601:logtimestamp}" ]
        add_tag => [ "grokdated", "grokked"]
      }
      date {
        match => [ "logtimestamp", "YYYY-MM-dd HH:mm:ss,SSS", "YYYY-MM-dd HH:mm:ss.SSSSSS", "ISO8601" ]
        add_tag => [ "dated" ]
      }
    }
  }
  output {
    if [type] == "trade" or [type] == "freeswitch" or [type] == "uploader" {
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

  logstash::configfile { 'TRADE-FS-logs':
    content => $logstashconf,
    order   => 30,
  }

  # Ensure latest TRADE Kernel log is symlinked to EXSKernel.log so Logstash gets it.
  cron { 'TRADE-Kernel-log-symlink':
    environment => ['MAILTO=""', 'PATH=/bin:/usr/bin:/usr/local/bin'],
    command     => 'ln -sf /home/tradekernel/TRADE/logs/EXSKernel-`pgrep -n p28kernel`.log  /home/tradekernel/TRADE/logs/EXSKernel.log',
    user        => tradekernel,
    minute      => '*/30',
  }

  # This Upstart script starts TRADE but only after FreeSWITCH is listening on port 8021.
  file { "/etc/init/trade-kernel.conf":
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '644',
    source => 'puppet:///modules/profiles/trade-kernel-upstart-script',
  }

  # Modify perms so that users w/o sudo access can read files:
  file { '/home/tradekernel':
    ensure => directory,
    mode   => 'go+rx',
  }

  # This Upstart script starts the Recordings Uploader
  file { '/etc/init/recording_uploader.conf':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '644',
    source => 'puppet:///modules/profiles/freeswitch/recording_uploader_upstart_script',
  }

  # delete the old Upstart script:
  file { '/etc/init/rec_uploader.conf': ensure => absent, }

  # Recordings Uploader start-and-loop start script
  file { '/home/tradekernel/TRADE/bin/start_recuploader_and_loop.sh':
    ensure => present,
    owner  => 'tradekernel',
    group  => 'tradekernel',
    mode   => '755',
    source => 'puppet:///modules/profiles/freeswitch/start_recuploader_and_loop.sh',
  }

  # Deployment script for Recording Uploader:
  file { '/home/tradekernel/TRADE/bin/deploy_recording_uploader.sh':
    ensure => present,
    owner  => 'tradekernel',
    group  => 'tradekernel',
    mode   => '755',
    source => 'puppet:///modules/profiles/freeswitch/deploy_recording_uploader.sh',
  }

}
