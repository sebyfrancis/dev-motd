# For Redis servers.
# Broken out from the previously monolithic servers (Redis, Logstash and Elasticsearch)

class profiles::redis {
  # Redis (acts as broker between incoming logs and Logstash)
  class { 'redis::install': }

  # Allow OS, etc. to have 1000MB. Take remainder for Redis
  $freemem   = $::memorysize_mb - 1000
  $redis_mem = floor($freemem)

  redis::server { "$::hostname":
    redis_ip     => "$::ipaddress",
    redis_memory => "${redis_mem}m",
  }

  package { 'perl-Redis': ensure => latest, }

  file { "/usr/lib64/nagios/plugins/check_redis.pl":
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '755',
    source => 'puppet:///modules/profiles/check_redis.pl',
    ignore => '.git',
  }

  # Add MRPE check for Redis. Note: The used_memory_rss check's threshold is in bytes.
  $redis_mem_warn_limit = floor($::memorysize_mb * 1024 * 1024 / 2)

  file_line { 'check_redis':
    path  => '/etc/check_mk/mrpe.cfg',
    match => '^check_redis',
    line  => "check_redis /usr/lib64/nagios/plugins/check_redis.pl -H \$HOSTNAME -f -r  -q LLEN,logstashbaby,WARN:,CRIT:,PERF:YES --evicted_keys=WARN:,CRIT:,PERF:YES --used_memory_rss=WARN:${redis_mem_warn_limit},CRIT:,PERF:YES",
  }

  exec { 'disable-swap-for-redis': command => '/sbin/swapoff -a', }

}
