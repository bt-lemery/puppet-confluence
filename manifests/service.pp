# == Class: confluence::service
#
# Install confluence, See README.md for more.
#
class confluence::service (
  $service_file_location = $confluence::params::service_file_location,
  $service_file_template = $confluence::params::service_file_template,
  $service_lockfile      = $confluence::params::service_lockfile,
  $refresh_systemd       = $confluence::params::refresh_systemd,
) {

  if $confluence::systemd_module == 'camptocamp' {
    if($refresh_systemd) {
      include systemd::systemctl::daemon_reload
    }

    file { $service_file_location:
      content => template($service_file_template),
      mode    => '0755',
      notify  => [
        $refresh_systemd ? {
          true    => Class['systemd::systemctl::daemon_reload'],
          default => undef
        }
      ],
    }

    if $confluence::manage_service {
      service { 'confluence':
        ensure  => 'running',
        enable  => true,
        require => [ Class['confluence::config'], File[$service_file_location], ],
      }
    }
  }

  if $confluence::systemd_module == 'eyp' {
    systemd::service { 'confluence':
      description => 'Confluence Team Collaboration Software',
      after       => 'network.target',
      user        => $confluence::user,
      group       => $confluence::group,
      forking     => true,
      execstart   => "${confluence::webappdir}/bin/start-confluence.sh",
      execstop    => "${confluence::webappdir}/bin/stop-confluence.sh",
      env_vars    => [ "\"JAVA_HOME=${confluence::javahome}\"" ],
    }

    if $confluence::manage_service {
      service { 'confluence':
        ensure  => 'running',
        enable  => true,
        require => [ Class['confluence::config'], Systemd::Service['confluence'], ],
      }
    }
  }

}
