#
# Makefile.am for devtools/devtools/skeletons/config/src
#

yncludedir = @yncludedir@/samba-server

client_DATA =			\
	samba-server.ycp		\
	samba-server_auto.ycp	

ynclude_DATA =			\
	helps.ycp		\
	wizards.ycp		\
	dialogs.ycp		\
	complex.ycp		\
	routines.ycp

desktop_DATA =			\
	samba-server.desktop

module_DATA =			\
	SambaServer.ycp		\
	SambaServerWidgets.ycp

samba-server:
	ln -sf . samba-server

ycpchook = samba-server

YCPCFLAGS = -I.

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
 
