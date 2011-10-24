class rvm {

    require 'rvm::setup_'

}  # class rvm


###################################################


define rvm::install::pkg ( $ensure='present', $require=[] ) {

    require 'rvm::setup_'

    # 'rvm pkg {install,uninstall} {readline,iconv,curl,openssl,zlib,pkgconfig,ncurses,gettext,libxml2,libyaml}'

    case $name {
        'gettext':      { $check_file = 'libgettextlib.so' }
        'libxml2':      { $check_file = 'libxml2.so' }
        'libyaml':      { $check_file = 'libyaml.so' }
        'openssl':      { $check_file = 'libssl.so' }
        'pkgconfig':    { $check_file = 'pkgconfig' }
        'zlib':         { $check_file = 'libz.so' }
        default:        { $check_file = "lib$name.so" }
    }

    case $ensure {
        absent: {
            exec { "rvm pkg install $name":
                path    => '/usr/local/rvm/bin:/bin:/usr/bin',
                command => "rvm pkg uninstall $name",
                onlyif  => "ls -1d /usr/local/rvm/usr/lib/$check_file >/dev/null 2>&1",
                require => $require,
            }
        }
        default: {
            exec { "rvm pkg install $name":
                path    => '/usr/local/rvm/bin:/bin:/usr/bin',
                command => "rvm pkg install $name",
                creates => "/usr/local/rvm/usr/lib/$check_file",
                require => $require,
            }
        }
    }

}  # define rvm::install::pkg


###################################################


define rvm::install ( $ensure='present', $require=[] ) {

    require 'rvm::setup_'
    require 'rvm::setup::pkg_'

    case $ensure {
        absent: {
            exec { "rvm install $name":
                path    => '/usr/local/rvm/bin:/bin:/usr/bin',
                command => "rvm uninstall $name",
                onlyif  => "rvm list |grep '$name'",
                require => $require,
            }
        }
        default: {
            exec { "rvm install $name":
                path    => '/usr/local/rvm/bin:/bin:/usr/bin',
                command => "rvm install $name",
                timeout => 0,
                unless  => "rvm list |grep '$name'",
                require => $require,
            }
        }
    }

}  # define rvm::install


###################################################


define rvm::gem ( $gem              = $name,
                  $ruby             = '',
                  $version          = '',
                  $version_operator = '',
                  $ensure           = 'present'
                ) {

    if $ruby == '' {
        $use_ruby = ''
        $require = Class['rvm::default']
    } else {
        $use_ruby = "use $ruby"
        $require = Rvm::Install[$ruby]
    }

    if $version != '' {
        $versionstring = "-v '$version_operator$version'"
        $grepversionstring = "|grep $version"
    } else {
        $versionstring = ""
        $grepversionstring = ""
    }

    case $ensure {
        absent: {
            exec { "rvm $use_ruby gem install $gem $version_operator$version":
                path    => '/usr/local/rvm/bin:/bin:/usr/bin',
                command => "rvm use $ruby gem uninstall $gem $versionstring",
                onlyif  => "rvm use $ruby gem list |grep '$gem' $grepversionstring",
                require => $require,
            }
        }
        default: {
            exec { "rvm $use_ruby gem install $gem $version_operator$version":
                path    => '/usr/local/rvm/bin:/bin:/usr/bin',
                command => "rvm use $ruby gem install $gem $versionstring --no-rdoc --no-ri",
                unless  => "rvm use $ruby gem list |grep '$gem' $grepversionstring",
                require => $require,
            }
        }
    }

}  # define rvm::install


###################################################


class rvm::default ( $ruby ) {

    if $ruby != 'system' {
        $require = Rvm::Install[$ruby]
    } else {
        $require = Class['rvm::setup_']
    }

    exec { "rvm default $ruby":
        path    => '/usr/local/rvm/bin:/bin:/usr/bin',
        command => "rvm use $ruby --default --force",
        unless  => "rvm current |grep '^$name\$'",
        require => $require,
    }

}  # define rvm::install



###################################################
##
##  Please do not include the below classes directly in the nodes
##
###################################################


class rvm::setup_ {

    require 'git'
    require 'devel'
    require 'libs::devel'

    File {
        mode    => '0644',
    }

    file { '/var/tmp/install_rvm':
        source  => 'puppet:///rvm/install_rvm',
        mode    => '0744',
    }

    exec { 'install RVM':
        command => '/var/tmp/install_rvm',
        creates => '/usr/local/rvm',
        require => File['/var/tmp/install_rvm'],
    }

    file { '/etc/profile.d/rvm.sh':
        ensure  => absent,
        require => Exec['install RVM'],
    }

    file { '/etc/rvmrc':
        source  => 'puppet:///rvm/rvmrc',
    }

    file { '/etc/gemrc':
        source  => 'puppet:///rvm/gemrc',
    }

    filesection { "bashrc-rvm":
        file        => "/etc/bashrc",
        sectionname => 'rvm',
        lines       => '[[ -s "/usr/local/lib/rvm" ]] && . "/usr/local/lib/rvm" # This loads RVM into shell AND ssh sessions.
[[ -s "/usr/local/rvm/scripts/rvm" ]] && source "/usr/local/rvm/scripts/rvm"  # This loads RVM into a shell session.',
    }

}  # class rvm::setup_


###################################################


class rvm::setup::pkg_ {

    rvm::install::pkg { 'zlib': }
    rvm::install::pkg { 'readline': }
    rvm::install::pkg { 'libyaml': }

}  # rvm::setup::pkg_
