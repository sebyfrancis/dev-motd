# For ACD-specific configs

class profiles::acd {
  # Add MRPE check to show ACD EAR version:
  file_line { 'ACD-EAR-ver':
    path  => '/etc/check_mk/mrpe.cfg',
    match => '^ACD-EAR-ver',
    line  => "ACD-EAR-ver /usr/lib64/nagios/plugins/check_file_exists /var/resin/autodeploy/*md5",
  }

  file { "/usr/local/bin/restart-ACD.sh":
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '755',
    source => 'puppet:///modules/profiles/restart-ACD.sh',
    ignore => '.git',
  }

  # Restart ACD periodically.
  # Get the day of the week for the cron job from Hiera
  $_acd_restart_day = hiera('acd_restart_day')

  cron { 'restart-ACD-perioidically':
    command => '/usr/local/bin/restart-ACD.sh',
    user    => root,
    hour    => '6',
    minute  => '0',
    weekday => "$_acd_restart_day",
  }

  # Logs for Logstash to read:
  $_redis_rr_dns_name  = hiera('redis_rr_dns_name')
  $_logstash_redis_key = hiera('logstash_redis_key')

  $logstashconf        = '
  input {
    file {
      type => "acd"
      path => [ "/var/log/resin/jvm*log", "/var/log/resin/watchdog*", "/var/log/resin/platform28.log" ]
      exclude => ["*.gz", "*.bz2"]
    }
  }
  filter {
    if [type] == "acd" {
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
    if "is being taken offline due to 4 Voice" in [message] {
      email {
        from => "logstash.alert@acd.aws1.platform28.com"
        subject => "ALERT! Possible voice connection issue from ACD to agent desktop(s)"
        to => "noc+acd@platform28.com"
        via => "smtp"
        body => "Possible voice connection issue from ACD to a user agent desktop. Here is the log entry:   \n   %{message}"
      }
    }
    if "org.hibernate.StaleStateException: Batch update returned unexpected row count from" in [message] {
      email {
        from => "logstash.alert@acd.aws1.platform28.com"
        subject => "ALERT! Possible ACD <-> Database conn issue."
        to => "noc+acd@platform28.com"
        via => "smtp"
        body => "Possible  ACD <-> Database conn issue. You may need to cut over to 2nd ACD (shutdown current ACD). Look at the current logs for errors. Here is the log entry:   \n \n  %{message}"
      }
    }
    if "Timed out acquiring write lock" in [message] {
      email {
        from => "logstash.alert@acd.aws1.platform28.com"
        subject => "Alert! ACD timed out trying to acquire a write lock."
        to => "noc+acd@platform28.com"
        via => "smtp"
        body => "Possible Hazelcast issue. ACD did not acquire a write lock. Here is the log entry:   \n   %{message}"
      }
    }
    if "STUCK AGENT" in [message] {
      email {
        from => "logstash.alert@acd.aws1.platform28.com"
        subject => "Alert! ACD reports STUCK AGENT."
        to => "noc+acd@platform28.com"
        via => "smtp"
        body => "STUCK AGENT error on ACD. Here is the log entry:   \n   %{message}"
      }
    }
    if [type] == "acd" {
      redis {
        # hardcoded. future: update $logstashconf to use double-quotes, then drop in Hiera vars
        # or better yet, turn this into a template.
        host      => "redis.aws1.platform28.com"
        data_type => "list"
        key       => "logstashbaby"
      }
    }

  }'

  logstash::configfile { 'acd-logs':
    content => $logstashconf,
    order   => 30,
  }

}
