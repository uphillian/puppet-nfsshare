class nfs {
				include nfs::server
}

class nfs::server {
				if $::osmajor == 5 {
					package { 'portmap':}
				} else {
					package { 'rpcbind':}
				}
				package {'nfs-utils': }
				service { ['nfs','nfslock' ]: require => Package['nfs-utils'],
				}
				file {'nfs':
					path   => '/etc/sysconfig/nfs',
					source => 'puppet:///nfs/nfs',
					mode   => 0644,
					notify => Service['nfs'],
				}
				exec {'exportfs':
					path        => '/usr/sbin',
					command     => 'exportfs -a',
					refreshonly => true,
				}
}


define nfs_share ($nfsshare = $name, $nfsaccess = "*.$::domain", $nfsoptions = "rw,sync") {
	# define a line in the /etc/exports for for an nfs share
	# usage nfs_share {'/tftpboot': nfsaccess =>'*', nfsoptions => 'ro,sync'}
	# split options into an array, use an inline template to loop through the array and print the correct input for augeas.

  $nfsopts = split($nfsoptions,',')
	$options_set = inline_template("<% nfsopts.each do |opt| -%>set dir[.= \"<%= @nfsshare %>\"]/client[.=\"<%= @nfsaccess %>\"]/option[.=\"<%= opt %>\"] <%= opt%>\n<% end %>")
	augeas { "share_${nfsshare}_${nfsaccess}_${nfsoptions}":
		context => "/files/etc/exports",
		changes => [
						"set dir[.= \"$nfsshare\"] $nfsshare",
						"set dir[.= \"$nfsshare\"]/client[.=\"$nfsaccess\"] $nfsaccess",
						split ($options_set, "\n"),
		],
		notify => Exec['exportfs'],
	}
}
