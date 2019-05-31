# Sources for samba-server

module_DATA = \
  modules/SambaBackend.pm \
  modules/SambaBackendLDAP.pm \
  modules/SambaRole.pm \
  modules/UsersPluginSambaGroups.pm \
  modules/SambaServer.pm \
  modules/SambaTrustDom.pm \
  modules/SambaAccounts.pm \
  modules/UsersPluginSamba.pm \
  modules/SambaSecrets.pm \
  modules/SambaService.pm \
  modules/SambaBackendSimple.pm \
  modules/SambaPrinters.pm

module1dir = @moduledir@/YaPI
module1_DATA = \
  modules/YaPI/Samba.pm

client_DATA = \
  clients/users_plugin_samba.rb \
  clients/samba-server_auto.rb \
  clients/users_plugin_samba_groups.rb \
  clients/samba-server.rb

yncludedir = @yncludedir@/samba-server
ynclude_DATA = \
  include/samba-server/samba-options-local.rb \
  include/samba-server/wizards.rb \
  include/samba-server/dialogs-items.rb \
  include/samba-server/ldap-widget.rb \
  include/samba-server/dialogs.rb \
  include/samba-server/samba-options-global.rb \
  include/samba-server/complex.rb \
  include/samba-server/helps.rb

schemafilesdir = $(schemadir)/autoyast/rnc
schemafiles_DATA = \
  autoyast-rnc/samba-server.rnc

ydata_DATA = \
  data/add_machine.rb

desktop_DATA = \
  desktop/org.openSUSE.YaST.SambaServer.desktop

scalabledir = @icondir@/hicolor/scalable/apps
scalable_DATA = \
  icons/hicolor/scalable/apps/yast-samba-server.svg

EXTRA_DIST = $(module_DATA) $(module1_DATA) $(client_DATA) $(ynclude_DATA) $(schemafiles_DATA) $(ydata_DATA) $(desktop_DATA) $(scalable_DATA)

include $(top_srcdir)/Makefile.am.common
