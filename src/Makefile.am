#
# Makefile.am for devtools/devtools/skeletons/config/src
#

yncludedir = @yncludedir@/samba-server

client_DATA =			\
	samba-server.ycp		\
	samba-server_auto.ycp	

ynclude_DATA =			\
	samba-options-global.ycp	\
	samba-options-local.ycp		\
	helps.ycp		\
	wizards.ycp		\
	dialogs.ycp		\
	dialogs-items.ycp	\
	complex.ycp		\
	ldap-widget.ycp

desktop_DATA =			\
	samba-server.desktop

module_DATA =			\
	SambaRole.pm		\
	SambaServer.pm		\
	SambaService.pm		\
	SambaSecrets.pm		\
	SambaPrinters.pm	\
	SambaTrustDom.pm	\
	SambaAccounts.pm	\
	SambaBackend.pm		\
	SambaBackendLDAP.pm	\
	SambaBackendSimple.pm

YaPI_perldir = @moduledir@/YaPI

YaPI_perl_DATA = \
        YaPI/Samba.pm

ydata_DATA =                     \
	add_machine.ycp

samba-server:
	ln -sf . samba-server

ycpchook = samba-server

YCPCFLAGS = -I.

SUBDIRS = config
EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA) $(YaPI_perl_DATA) $(ydata_DATA)

include $(top_srcdir)/Makefile.am.common
 
