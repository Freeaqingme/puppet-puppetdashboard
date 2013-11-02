class puppetdashboard::install {

  case $puppetdashboard::install_method {
    'package' : {

      package { 'puppetdashboard':
        ensure => $puppetdashboard::manage_package,
        name   => $puppetdashboard::package,
      }
      
      if $puppetdashboard::bool_setup_mysql {
        Package['puppetdashboard'] ~> Exec['puppetdashboard_dbmigrate']
      }

    }
    
    'build': {
      
      group { 'puppet-dashboard':
        system => true
      }

      user { 'puppet-dashboard':
        system  => true,
        comment => 'Managed by Puppet',
  #      group   => 'puppet-dashboard',
        require => Group[ 'puppet-dashboard' ]
      }

      # See: http://docs.puppetlabs.com/dashboard/manual/1.2/bootstrapping.html
      exec { 'puppetdashboard-download':
        command => "wget http://puppetlabs.com/downloads/dashboard/puppet-dashboard-${puppetdashboard::version}.tar.gz && \
                    tar -xzvf puppet-dashboard-${puppetdashboard::version}.tar.gz && \
                    rm puppet-dashboard-${puppetdashboard::version}.tar.gz && \
                    chown -R root:wheel /usr/src/puppet-dashboard-${puppetdashboard::version}",
        cwd     => '/usr/src',
        creates => "/usr/src/puppet-dashboard-${puppetdashboard::version}"
      }

      file { 'puppetdashboard-symlink':
        path   => '/usr/local/share/puppet-dashboard',
        ensure => link,
        target => "/usr/src/puppet-dashboard-${puppetdashboard::version}",
        notify => $puppetdashboard::manage_service_autorestart,
      }

      if $puppetdashboard::bool_setup_mysql {
        Exec['puppetdashboard-download'] ~> Exec['puppetdashboard_dbmigrate']
        File['puppetdashboard-symlink'] -> Exec['puppetdashboard_dbmigrate']
      }

      # Not sure how to do this somewhat more dynamic without either 
      # not setting owner, or also touching /usr/share
      file { [ '/usr/share/puppet-dashboard', '/usr/share/puppet-dashboard/config' ]:
        ensure => 'directory',
        owner   => $puppetdashboard::config_file_owner,
        group   => $puppetdashboard::config_file_group,
      }
      
      file { $puppetdashboard::config_file_dir:
        ensure => 'directory'
      }
      
      if $puppetdashboard::bool_setup_mysql {
        Exec['puppetdashboard-download'] ~> Exec['puppetdashboard_dbmigrate']
        File['/usr/share/puppet-dashboard/config'] -> Exec['puppetdashboard_dbmigrate']
      }
      
      # gem install bundle
      # gem install bundler
      # gem install rack --version 1.1.2 (and rake?!)

    }

    'source': {
      fail('Installing from sources has not yet been implemented')
    }

    default: {
      fail('invalid parameter for $install_method')
    }
    
  }
  

}
