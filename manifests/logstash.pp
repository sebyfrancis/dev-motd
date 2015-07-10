# For Logstash servers.
# Broken out from the previously monolithic servers (Redis, Logstash and Elasticsearch)
#
# Still need to turn hard-coded items into Hiera variables where it makes sense.

class profiles::logstash {
  $_redis_servers      = hiera('redis_servers')
  $_logstash_redis_key = hiera('logstash_redis_key')
  $_es_cluster_name    = hiera('es_cluster_name')
  $_es_master_host     = hiera('es_master_host')

  package { 'jdk': ensure => latest, }

  package { 'python-pip': ensure => latest, }

  exec { 'disable-swap-for-logstash': command => '/sbin/swapoff -a', }

  ::logstash::configfile { 'server_config': content => template('profiles/logstash-server.conf.erb'), }

  # Adjust settings for Logstash instances running as 'servers':
  $ls_heap = floor($::memorysize_mb / 4)

  file_line { 'ls-heap-size':
    path  => '/etc/sysconfig/logstash',
    match => '^LS_HEAP_SIZE',
    line  => "LS_HEAP_SIZE=${ls_heap}m",
  }

  file_line { 'ls-nice':
    path  => '/etc/sysconfig/logstash',
    match => '^LS_NICE',
    line  => "LS_NICE=0",
  }

  file_line { 'ls-open-files':
    path  => '/etc/sysconfig/logstash',
    match => '^LS_OPEN_FILES',
    line  => "LS_OPEN_FILES=16084",
  }

}
