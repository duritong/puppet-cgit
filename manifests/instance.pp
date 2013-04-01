define cgit::instance(
  $ensure         = 'present',
  $domainalias    = 'absent',
  $base_dir       = 'absent',
  $ssl_mode       = false,
  $user           = 'absent',
  $group          = 'absent',
  $anonymous_http = true,
  $cgit_options   = {}
) {

  if ($ensure == 'present') and (($base_dir == 'absent') or ($user == 'absent') or ($group == 'absent')) {
    fail("You need to set \$base_dir, \$user and \$group for ${name} if present")
  }

  $htpasswd_file = "/var/www/git_htpasswds/${name}/htpasswd"
  file{["/var/cache/cgit/${name}","/var/www/git_suexec/${name}","/var/www/git_htpasswds/${name}" ]: }
    
  apache::vhost::template{
    $name:
      ensure => $ensure;  
  }
  if $ensure == 'present' {

    $default_cgit_options = {
      'root-title'  => $name,
      'root-desc'   => "${name}'s git repositories",
    }

    $repos_path = "${base_dir}/repositories"
    $projects_list = "${base_dir}/projects.list"

    include cgit::vhosts
    File["/var/cache/cgit/${name}","/var/www/git_suexec/${name}" ]{
      ensure  => directory,
      require => Package['cgit'],
      owner   => $user,
      group   => $group,
    }
    File["/var/cache/cgit/${name}"]{
      mode    => '0640',
    }
    File["/var/www/git_suexec/${name}"]{
      mode    => '0644',
    }
    File["/var/www/git_htpasswds/${name}"]{
      ensure  => directory,
      owner   => $user,
      group   => 'apache',
      mode    => '0640',
    }

    file{
      "/etc/cgitrc.d/${name}":
        content => template('cgit/cgitrc.vhosts.erb'),
        require => Package['apache'],
        owner   => root,
        group   => $group,
        mode    => 0644;
      $htpasswd_file:
        ensure  => file,
        owner   => $user,
        group   => 'apache',
        mode    => '0640';
      "/var/www/git_suexec/${name}/cgit-suexec-wrapper.sh":
        content => "#!/bin/bash\n# Wrapper for cgit\nexec /var/www/cgi-bin/cgit\n",
        owner   => $user,
        group   => $group,
        mode    => '0755';
      "/var/www/git_suexec/${name}/gitolite-suexec-wrapper.sh":
        content => template('cgit/gitolite-suexec-wrapper.sh.erb'),
        owner   => $user,
        group   => $group,
        mode    => '0755';
    }

    Apache::Vhost::Template[$name]{
      domainalias       => $domainalias,
      template_partial  => 'cgit/httpd.partial.erb',
      template_vars     => {
        repos_path    => $repos_path,
        htpasswd_file => $htpasswd_file,
        user          => $user,
        group         => $group,
      },
      mod_security      => false,
      logprefix         => "${name}-",
      logpath           => '/var/log/httpd',
      path              => 'really_absent',
      path_is_webdir    => true,
      ssl_mode          => $ssl_mode,
    }

  } else {
    File["/var/cache/cgit/${name}","/var/www/git_suexec/${name}","/var/www/git_htpasswds/${name}"]{
      ensure  => absent,
      purge   => true,
      force   => true,
      recurse => true,
    }
  }
  
}
