# == Class jupyterhub::install
#
# This class is called from jupyterhub for install.
#
class jupyterhub::install {

  case $facts['os']['name'] {
    'Ubuntu': { class {'::nodejs':
      manage_package_repo       =>  false,
      nodejs_dev_package_ensure =>  'present',
      npm_package_ensure        =>  'present',
    }
    }
    'Fedora': { class {'::nodejs':
      manage_package_repo       =>  false,
      nodejs_dev_package_ensure =>  'present',
      npm_package_ensure        =>  'present',
    }
    }
    'CentOS':{ class { '::nodejs':
      repo_url_suffix       => '13.x',
      nodejs_package_ensure => '13.8.0', }
    }
    default: { class { '::nodejs': }
    }
  }

  if $jupyterhub::manage_git == true {
    ensure_packages(['git'], { before => Python::Pyvenv[$::jupyterhub::pyvenv]})
  }

  case $facts['os']['family'] {
    'Debian': { ensure_packages(['python3.4-venv'], { before =>  Python::Pyvenv[$::jupyterhub::pyvenv]}) }
    'RedHat': { ensure_packages(['python36'],  {
      require => Class['::epel'],
      before  => Python::Pyvenv[$::jupyterhub::pyvenv]})
    }
    default: { ensure_packages(['python34'],  { before =>  Python::Pyvenv[$::jupyterhub::pyvenv]}) }
  }

  user { $::jupyterhub::jupyterhub_username:
    ensure     => present,
    managehome => true,
  }

  file { $::jupyterhub::config_dir:
    ensure  => directory,
    owner   => $::jupyterhub::jupyterhub_username,
    recurse => true,
    require => User[$::jupyterhub::jupyterhub_username],
  }

  file { $::jupyterhub::jupyterhub_dir:
    ensure  => directory,
    owner   => $::jupyterhub::jupyterhub_username,
    require => User[$::jupyterhub::jupyterhub_username],
  }

  python::pyvenv { $::jupyterhub::pyvenv:
    ensure  => present,
    version => $::jupyterhub::python_version,
    owner   => $::jupyterhub::jupyterhub_username,
    group   => $::jupyterhub::jupyterhub_group,
    require => File[$::jupyterhub::jupyterhub_dir],
  }

  python::pip { 'jupyter':
    ensure     => $::jupyterhub::pip_version_jupyter,
    pkgname    => 'jupyter',
    virtualenv => $::jupyterhub::pyvenv,
    owner      => $::jupyterhub::jupyterhub_username,
    require    => Python::Pyvenv[$::jupyterhub::pyvenv],
  }

  python::pip { 'jupyterhub':
    ensure     => $::jupyterhub::pip_version_jupyterhub,
    pkgname    => 'jupyterhub',
    virtualenv => $::jupyterhub::pyvenv,
    owner      => $::jupyterhub::jupyterhub_username,
    require    => Python::Pyvenv[$::jupyterhub::pyvenv],
  }

  if $::jupyterhub::sudospawner_enable == true {

    python::pip { 'sudospawner':
      ensure     => $::jupyterhub::pip_version_sudospawner,
      pkgname    => 'sudospawner',
      virtualenv => $::jupyterhub::pyvenv,
      owner      => $::jupyterhub::jupyterhub_username,
      require    => Python::Pyvenv[$::jupyterhub::pyvenv],
    }
  }

  if $::jupyterhub::systemdspawner_enable == true {

    python::pip { 'systemdspawner':
      ensure     => $::jupyterhub::pip_version_systemdspawner,
      pkgname    => 'jupyterhub-systemdspawner',
      virtualenv => $::jupyterhub::pyvenv,
      owner      => $::jupyterhub::jupyterhub_username,
      require    => Python::Pyvenv[$::jupyterhub::pyvenv],
    }
  }

  if $::jupyterhub::batchspawner_enable == true {

    python::pip { 'batchspawner':
      ensure     => $::jupyterhub::pip_version_batchspawner,
      pkgname    => 'batchspawner',
      virtualenv => $::jupyterhub::pyvenv,
      owner      => $::jupyterhub::jupyterhub_username,
      require    => Python::Pyvenv[$::jupyterhub::pyvenv],
    }
  }

  if $::jupyterhub::wrapspawner_enable == true {

    python::pip { 'wrapspawner':
      ensure     => $::jupyterhub::pip_version_wrapspawner,
      pkgname    => 'wrapspawner',
      virtualenv => $::jupyterhub::pyvenv,
      owner      => $::jupyterhub::jupyterhub_username,
      require    => Python::Pyvenv[$::jupyterhub::pyvenv],
    }
  }

  if $::jupyterhub::ldap_enable == true {
    python::pip { 'jupyterhub-ldapauthenticator':
      ensure     => $::jupyterhub::pip_version_jupyterhub_ldapauthenticator,
      pkgname    => 'jupyterhub-ldapauthenticator',
      virtualenv => $::jupyterhub::pyvenv,
      owner      => $::jupyterhub::jupyterhub_username,
      require    => Python::Pyvenv[$::jupyterhub::pyvenv],
    }
  }

  if $::jupyterhub::oauth_enable == true {

    python::pip { 'oauthenticator':
      ensure     => $::jupyterhub::pip_version_oauthenticator,
      pkgname    => 'oauthenticator',
      virtualenv => $::jupyterhub::pyvenv,
      owner      => $::jupyterhub::jupyterhub_username,
      require    => Python::Pyvenv[$::jupyterhub::pyvenv],
    }

    python::pip { 'requests-oauthlib':
      ensure     => $::jupyterhub::pip_version_requests_oauthlib,
      pkgname    => 'requests-oauthlib',
      virtualenv => $::jupyterhub::pyvenv,
      owner      => $::jupyterhub::jupyterhub_username,
      require    => Python::Pyvenv[$::jupyterhub::pyvenv],
    }
  }

  if $::jupyterhub::custom_packages_enable == true {

    $jupyterhub::custom_packages.each |String $custom_package | {

      python::pip { $custom_package:
        pkgname    => $custom_package,
        virtualenv => $::jupyterhub::pyvenv,
        owner      => $::jupyterhub::jupyterhub_username,
        require    => Python::Pyvenv[$::jupyterhub::pyvenv],
      }
    }
  }

  package { 'configurable-http-proxy':
    ensure   => 'present',
    provider => 'npm',
    require  =>  Class['::nodejs'],
  }

  file { '/usr/lib/node_modules/configurable-http-proxy':
    ensure  => directory,
    recurse => true,
    mode    => 'a+Xr',
  }
}
