# Makefile.am for mail-server/src

yncludedir = @yncludedir@/samba-server

client_DATA =			\
	users_plugin_samba.ycp  \
	users_plugin_samba_groups.ycp

module_DATA =			\
	UsersPluginSamba.pm \
	UsersPluginSambaGroups.pm

EXTRA_DIST = $(client_DATA) $(module_DATA)

include $(top_srcdir)/Makefile.am.common
