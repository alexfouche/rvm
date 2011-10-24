# RVM module for Puppet
*Alexandre Fouché - alexandrefouche.com*


The module install RVM (system wide) in its default location /usr/local/rvm, so it will not mix with RPM managed files. The module will add some lines in /etc/bashrc and remove /etc/profile.d/rvm.sh. It will also create a /etc/{rvmrc,gemrc}.
The /etc/bashrc file will change your path to ruby depending which RVM default you chose, and load your environment

RVM can always be uninstalled with 'rvm implode', and remove the /etc/{rvmrc,gemrc} files and removing the line in /etc/bashrc

# Usage example:

    node 'a.b.com' {
        rvm::install { 'ruby-1.9.2-p290': }
        class { 'rvm::default': ruby => 'ruby-1.9.2-p290' }
        rvm::gem { ['bundler', 'passenger', 'guid']: }
    }

    node 'a.b.com' {
        include rvm
        class { 'rvm::default': ruby => 'system' }
        rvm::install { 'ruby-1.8.7-p352': }

        rvm::gem { 'net-ssh':
            version => '2.1.4',
            ruby    => 'ruby-1.8.7-p352',
            before  => Rvm::Gem['fog'],
        }
    }

    node 'a.b.com' {
        rvm::install { 'ruby-1.9.2-p290': }
        rvm::install { 'ruby-1.8.7-p352': }

        class { 'rvm::default': ruby => 'ruby-1.9.2-p290' }

        rvm::gem { 'net-ssh':
            version => '2.1.4',
            ruby    => 'ruby-1.8.7-p352',
            before  => Rvm::Gem['fog'],
        }

        rvm::gem { 'bluepill':
            version             => '0.0.50',
            version_operator    => '>=',
            ruby                => 'ruby-1.8.7-p352',
        }
    }

# Prerequisites

My RVM Puppet module requires to edit the /etc/bashrc file. For that, it uses a Filesection type, which is simply:

    # AF
    define filesection($file, $sectionname, $lines='', $ensure = 'present') {
       case $ensure {
          default : { err ( "unknown ensure value ${ensure}" ) }
          present: {
             exec { "exec add ${sectionname} $file":
                path => ["/bin", "/usr/bin" ],
                command => "cat <<EOF >>'${file}'

    ## PUPPET BEGIN ${sectionname}
    ${lines}
    ## PUPPET END ${sectionname}
    EOF",
                unless => "grep -qFx '## PUPPET BEGIN ${sectionname}' '${file}'"
             }
          }
          absent: {
            remove_filesection_lines {"filesection $name":
                file    => "$file",
                from    => "^## PUPPET BEGIN ${sectionname}",
                to      => "^## PUPPET END ${sectionname}",
             }
          }
       }
    }

    define remove_filesection_lines ( $searchfirst="", $file="", $from="", $to="", $require=[] ) {
        if $file !="" and $from !="" and $to !="" {
            if $searchfirst == "" {
                exec { "remove_filesection_lines $name":
                    path => "/bin:/usr/bin",
                    command => "/bin/cat <<EOF |ed '${file}'
    /${from}
    ka
    -
    /${to}
    'a,.d
    w
    q
    EOF",
                    onlyif  => "grep \"$from\" '${file}'",
                    require => $require,
                }
            } else {
                exec { "remove_filesection_lines $name":
                    path => "/bin:/usr/bin",
                    command => "/bin/cat <<EOF |ed '${file}'
    /${searchfirst}
    +
    ?${from}
    ka
    -
    /${to}
    'a,.d
    w
    q
    EOF",
                    onlyif => "grep \"$searchfirst\" '${file}'",
                    require => $require,
                }
            }
        }
    }
