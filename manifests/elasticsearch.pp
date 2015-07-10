# For Elasticsearch servers.
# Broken out from the previously monolithic servers (Redis, Logstash and Elasticsearch)
#
# Still need to turn hard-coded items into Hiera variables where it makes sense.
# NOTE! You will need to create data directories for Elasticsearch FIRST before you run this manifest,
# since the elasticsearch module used here will mkdir the es_datadirs specified.
# - so create EBS volumes first and mount them to the server,
# - under /data/elasticsearch/<localdisk<x>>|<ebsdisk<y>>/
#   [Don't bother using attached Ephemeral instance stores - they don't perform as well as EBS SSD disks.]
#
# mkdir -p /data/elasticsearch/{ebsdisk1,ebsdisk2,ebsdisk3,ebsdisk4,ebsdisk5}
# cd /data
# chown -R elasticsearch:elasticsearch elasticsearch/
#
# for *each* EBS volume:
#   mkfs.ext4 /dev/xvdc
#
# vim /etc/fstab, and add the various disks. Example lines:
#   /dev/xvdf       /data/elasticsearch/ebsdisk5    ext4    defaults,noatime        0 2
#
# mount -a

class profiles::elasticsearch {
  $_es_cluster_name      = hiera('es_cluster_name')
  $_es_master_host       = hiera('es_master_host')
  $_es_datadirs          = hiera('es_datadirs')
  $_logstash_kibana_host = hiera('logstash_kibana_host')

  # package { 'java-1.8.0-openjdk': ensure => latest, }
  package { 'jdk': ensure => latest, }

  package { 'python-pip': ensure => latest, }

  # Elasticsearch:
  yumrepo { 'elasticsearch-1.4':
    baseurl  => 'http://packages.elasticsearch.org/elasticsearch/1.4/centos',
    descr    => 'Elasticsearch repository for 1.4.x packages',
    enabled  => 1,
    gpgcheck => 0,
  }

  group { 'elasticsearch': ensure => present, } ->
  user { 'elasticsearch':
    ensure  => present,
    comment => 'Elasticsearch',
    home    => '/usr/share/elasticsearch',
    shell   => '/sbin/nologin',
    groups  => 'elasticsearch',
    require => Group['elasticsearch'],
  } ->
  file { '/data/': ensure => 'directory', } ->
  file { '/data/elasticsearch/':
    ensure => 'directory',
    owner  => 'elasticsearch',
    group  => 'elasticsearch',
    mode   => '775',
  } ->
  class { '::elasticsearch': require => [Yumrepo['elasticsearch-1.4'], User['elasticsearch']], }

  # Set JVM XMX memory limit to 1/2
  $freemem = $::memorysize_mb / 2
  $jvm_xmx = floor($freemem)

  ::elasticsearch::instance { "$::hostname":
    ensure        => present,
    datadir       => $_es_datadirs,
    config        => {
      'cluster.name'           => "${_es_cluster_name}",
      'discovery.zen.ping.multicast.enabled' => 'false',
      'discovery.zen.ping.unicast.hosts'     => ["${_es_master_host}"],
      'http.cors.enabled'      => 'true',
      'http.cors.allow-origin' => "${_logstash_kibana_host}",
      'bootstrap.mlockall'     => 'true',
      'indices.memory.index_buffer_size'     => '50%',
      'index.refresh_interval' => '15s',
      'index.translog.flush_threshold_ops'   => '50000',
    }
    ,
    init_defaults => {
      'ES_HEAP_SIZE' => "${jvm_xmx}m",
    }
    ,
    status        => 'enabled',
  }

  notify { 'configreminder': message => "NOTE! You have to first add the disks for Elasticsearch's datadirs, and mount them. See notes at top of manifest.", 
  }

  ::elasticsearch::plugin { 'lmenezes/elasticsearch-kopf':
    module_dir => 'kopf',
    instances  => "$::hostname",
  }

  ::elasticsearch::plugin { 'karmi/elasticsearch-paramedic':
    module_dir => 'paramedic',
    instances  => "$::hostname",
  }

  ::elasticsearch::plugin { 'mobz/elasticsearch-head':
    module_dir => 'head',
    instances  => "$::hostname",
  }

  # Settings below are OS-level tuning per Elasticsearch's recommendations:
  class { 'ulimit':
    purge => false,
  }

  ulimit::rule { 'es-file-max':
    ulimit_domain => 'elasticsearch',
    ulimit_type   => '-',
    ulimit_item   => 'nofile',
    ulimit_value  => '65000',
  }

  ulimit::rule { 'es-max-locked-memory':
    ulimit_domain => 'elasticsearch',
    ulimit_type   => '-',
    ulimit_item   => 'memlock',
    ulimit_value  => 'unlimited',
  }

  sysctl { "vm.max_map_count":
    ensure  => present,
    value   => "262144",
    comment => "Increase max NioFS and MMapFS map count",
  }

  exec { 'disable-swap-for-es': command => '/sbin/swapoff -a', }

  cron { 'delete-old-es-log-files':
    command => 'find /var/log/elasticsearch -name \*.log.\* -mtime +7 -exec rm {} \;',
    user    => root,
    hour    => '5',
    minute  => '01',
  }

}
