# == Class jupyterhub::config
#
# This class is called from jupyterhub for service config.
#
class jupyterhub::config {

  file { '/var/log/jupyterhub.log':
    ensure => file,
    owner  => $jupyterhub::jupyterhub_username,
  }

  if $jupyterhub::manage_config == true {

    file { "${jupyterhub::config_dir}/jupyterhub_config.py":
      ensure  => file,
      owner   => $jupyterhub::jupyterhub_username,
      content => epp("${module_name}/jupyterhub_config.py.epp"),
      require => File[$jupyterhub::config_dir],
    }
  }

  if $jupyterhub::sudospawner_enable == true {

    file { '/etc/sudoers.d/jupyterhub_sudospawner':
      ensure  => file,
      owner   => root,
      content => epp("${module_name}/jupyterhub_sudoers.epp"),
      mode    => '0440',
    }
  }

  if $jupyterhub::batchspawner_enable == true {

    file { '/etc/sudoers.d/jupyterhub_batch':
      ensure  => file,
      owner   => root,
      content => epp("${module_name}/jupyterhub_batch.epp"),
      mode    => '0440',
    }
  }

  file { "${jupyterhub::jupyterhub_dir}/start_jupyterhub.sh":
    ensure  => file,
    owner   => $jupyterhub::jupyterhub_username,
    mode    => '0755',
    content => epp("${module_name}/start_jupyterhub.sh.epp"),
  }

  file { "/etc/systemd/system/${jupyterhub::service_name}.service":
    ensure  => file,
    owner   => 'root',
    content => epp("${module_name}/jupyterhub.service.epp"),
  }
}
