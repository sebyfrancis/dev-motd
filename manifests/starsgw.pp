# For STARS gateways

class profiles::starsgw {
  # delete old OpenEJB log files:
  cron { 'delete-old-openejb-log-files':
    environment => ['MAILTO=""', 'PATH=/bin:/usr/bin:/usr/sbin:/usr/local/bin'],
    command     => 'find /home/wsgateway/apache-openejb-4.6.0/logs/  -name \*.log.\* -mime +14 -exec rm {} \;',
    user        => root,
    minute      => '0',
    hour        => '6',
  }

  # Logstash configs for STARS gw
  $_redis_rr_dns_name  = hiera('redis_rr_dns_name')
  $_logstash_redis_key = hiera('logstash_redis_key')

  $logstashconf        = '
  input {
    file {
      type => "stars"
      path => [ "/home/wsgateway/logs/openejb.log" ]
      exclude => ["*.gz", "*.bz2"]
    }
  }

 filter {
    if [type] == "stars" {
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
    if [type] == "stars" {
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

  logstash::configfile { 'starsgw-logs':
    content => $logstashconf,
    order   => 30,
  }

}
