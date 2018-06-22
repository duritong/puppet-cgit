# create an instance for cgit and gitolite
define cgit::instance(
  $base_dir,
  $ensure           = 'present',
  $configuration    = {},
  $domainalias      = 'absent',
  $ssl_mode         = false,
  $user             = 'absent',
  $group            = 'absent',
  $anonymous_http   = true,
  $cgit_options     = {},
  $clone_prefixes   = undef,
  $nagios_check     = false,
  $nagios_web_check = 'OK',
  $nagios_web_use   = 'generic-service',
) {

  if ($ensure == 'present') and (($user == 'absent') or ($group == 'absent')) {
    fail("\$user and \$group are required for  ${name}")
  }

  $htpasswd_file = "/var/www/git_htpasswds/${name}/htpasswd"
  file{["/var/cache/cgit/${name}","/var/www/git_suexec/${name}",
    "/var/www/git_htpasswds/${name}","/etc/cgitrc.d/${name}" ]: }

  $projects_list = "${base_dir}/projects.list"
  if $ensure == 'present' {

    $default_cgit_options = {
      'root-title'  => $name,
      'root-desc'   => "${name}'s git repositories",
    }

    $repos_path = "${base_dir}/repositories"

    include ::cgit::vhosts
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
      seltype => 'httpd_sys_content_t',
    }
    File["/var/www/git_htpasswds/${name}"]{
      ensure => directory,
      owner  => $user,
      group  => 'apache',
      mode   => '0640',
    }
    File["/etc/cgitrc.d/${name}"]{
      content => template('cgit/cgitrc.vhosts.erb'),
      require => Package['apache'],
      owner   => root,
      group   => $group,
      mode    => '0644'
    }

    file{
      $htpasswd_file:
        ensure => file,
        owner  => $user,
        group  => 'apache',
        mode   => '0640';
      "/var/www/git_suexec/${name}/cgit-suexec-wrapper.sh":
        content => "#!/bin/bash
# Wrapper for cgit
export VHOST=${name}
export TMPDIR='${base_dir}/git_tmp'
exec /var/www/cgi-bin/cgit
",
        owner   => $user,
        group   => $group,
        mode    => '0755';
      "/var/www/git_suexec/${name}/gitolite-suexec-wrapper.sh":
        content => template('cgit/gitolite-suexec-wrapper.sh.erb'),
        owner   => $user,
        group   => $group,
        mode    => '0755';
    }

    apache::vhost::template{$name:
      ensure           => $ensure,
      domainalias      => $domainalias,
      configuration    => $configuration,
      template_partial => 'cgit/httpd.partial.erb',
      template_vars    => {
        repos_path     => $repos_path,
        htpasswd_file  => $htpasswd_file,
        anonymous_http => $anonymous_http,
        user           => $user,
        group          => $group,
      },
      mod_security     => false,
      logprefix        => "${name}-",
      logpath          => '/var/log/httpd',
      path             => 'really_absent',
      path_is_webdir   => true,
      ssl_mode         => $ssl_mode,
    }

  } else {
    File["/var/cache/cgit/${name}","/var/www/git_suexec/${name}",
        "/var/www/git_htpasswds/${name}","/etc/cgitrc.d/${name}"]{
      ensure  => absent,
      purge   => true,
      force   => true,
      recurse => true,
    }
  }

  if $nagios_check {
    $nagios_check_code = $anonymous_http ? {
      true      => $nagios_web_check,
      default   => '401'
    }
    nagios::service::http{"gitweb_${name}":
      ensure       => $ensure,
      check_domain => $name,
      ssl_mode     => $ssl_mode,
      check_code   => $nagios_check_code,
      use          => $nagios_web_use,
    }
  }

  if str2bool($::selinux) {
    # unfortunately current (EL6) selinux capabilities do not allow
    # us to do that without restorecond
    selinux::restorecond::entry{
      $projects_list:
        ensure => $ensure;
    }
  }
}
