#
# Makefile.am for devtools/devtools/skeletons/config/src
#

yncludedir = @yncludedir@/samba-server

client_DATA =			\
	samba-server.ycp		\
	samba-server_auto.ycp	

ynclude_DATA =			\
	samba-synonym-map.ycp		\
	samba-options-global.ycp	\
	samba-options-local.ycp		\
	helps.ycp		\
	wizards.ycp		\
	dialogs.ycp		\
	complex.ycp		\
	routines.ycp

desktop_DATA =			\
	samba-server.desktop

module_DATA =			\
	SambaServer.ycp		\
	SambaServerWidgets.ycp	\
	SambaServerPassdb.pm	\
	SambaSecrets.pm

YaPI_perldir = @moduledir@/YaPI

YaPI_perl_DATA = \
        YaPI/Samba.pm

ydata_DATA =                     \
	add_machine.ycp

samba-server:
	ln -sf . samba-server

ycpchook = samba-server

YCPCFLAGS = -I.

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA) $(YaPI_perl_DATA) $(ydata_DATA)

include $(top_srcdir)/Makefile.am.common
 
