# For Rundeck server(s):

class profiles::rundeck {
  # Add MRPE check for Rundeck server:
  file_line { 'is_rundeck_running':
    path  => '/etc/check_mk/mrpe.cfg',
    match => '^rundeck_server',
    line  => "rundeck_server /usr/lib64/nagios/plugins/check_procs -c 1: -u rundeck -a rundeck",
  }
}
