# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2006-2012 Novell, Inc. All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------

# File:	include/samba-server/helps.ycp
# Package:	Configuration of samba-server
# Summary:	Help texts of all the dialogs
# Authors:	Stanislav Visnovsky <visnov@suse.cz>
#		Lukas Ocilka <locilka@suse.cz>
#
# $Id$
module Yast
  module SambaServerHelpsInclude
    def initialize_samba_server_helps(include_target)
      textdomain "samba-server"

      # All helps are here
      @HELPS = {
        # Read dialog help 1/2
        "read"                                => _(
          "<p><b><big>Initializing Samba Server Configuration</big></b><br>\nPlease wait...<br></p>\n"
        ) +
          # Read dialog help 2/2
          _(
            "<p><b><big>Aborting Initialization</big></b><br>\nSafely abort the configuration utility by pressing <b>Abort</b> now.</p>\n"
          ),
        # Write dialog help 1/2
        "write"                               => _(
          "<p><b><big>Saving Samba Server Configuration</big></b><br>\nPlease wait...<br></p>\n"
        ) +
          # Write dialog help 2/2
          _(
            "<p><b><big>Aborting Saving</big></b><br>\n" +
              "Abort the save procedure by pressing <b>Abort</b>.\n" +
              "An additional dialog will inform you whether it is safe to do so.\n" +
              "</p>\n"
          ),
        # Samba selecting workgroup or domain 1/1 - Installation step 1
        "inst_step1"                          => _(
          "<p><b><big>Workgroup or Domain Selection</big></b><br>\n" +
            "Select existing name of workgroup or domain or type your own new name and click <b>Next</b>.\n" +
            "</p>\n"
        ),
        # Samba select Samba Server type - Installation step 2
        "inst_step2"                          => _(
          "<p><b><big>Samba Server Type</big></b></p>\n" +
            "<p>A domain controller allows Windows clients to log in to a Windows domain.</p>\n" +
            "<p>The backup controller uses another domain controller for validation.\n" +
            "The primary controller uses its own information about users and their passwords.</p>\n" +
            "<p>The options available in the configuration dialogs depend on the settings in this selection.</p>"
        ),
        # Samba select Samba Server type - Installation step 2
        "inst_step2_no_bdc"                   => _(
          "<p><b><big>Samba Server Type</big></b></p>\n" +
            "<p>A domain controller allows Windows clients to log in to a Windows domain.</p>\n" +
            "<p>The options available in the configuration dialogs \n" +
            "depend on the settings in this selection.</p>"
        ),
        # Share list dialog help 1/4
        "smb_conf_tab_shares"                 => _(
          "<p><b><big>Shares</big></b></p>"
        ) +
          _(
            "<p>This is a list of already configured shares, whether they \nare enabled or disabled, and some basic information about them.<br></p>"
          ) +
          # Share list dialog help 2/4
          _(
            "<p>A share can be enabled or disabled.\n" +
              "A disabled share is not accessible, but its\n" +
              "configuration is still written into the configuration file.\n" +
              "So the share can be later enabled again.\n" +
              "</p>"
          ) +
          # Share list dialog help 3/4
          _(
            "<p>Some of the shares are special. For example, the share\n" +
              "Homes is a special system share for accessing home directories\n" +
              "of users. The system shares can be hidden from the table\n" +
              "by selecting <b>Do Not Show System Shares</b> in the <b>Filter</b>\n" +
              "menu.</p>\n"
          ) +
          # Share list dialog help 4/4
          _(
            "<p>Use <b>Add</b> to add a new share, <b>Edit</b> to modify\n" +
              "already existing share, and <b>Delete</b> to \n" +
              "remove the information about a share.</p>\n"
          ),
        # Identity dialog help 1/5
        "smb_conf_tab_identity"               => _(
          "<p><b><big>Identity</big></b><br>\n" +
            "These options allow setup of the identity of the server and its\n" +
            "primary role in the network.</p>\n"
        ),
        # Samba role dialog help 2/5
        "smb_conf_tab_base_settings"          => _(
          "<p>The base settings set up the domain and the\n" +
            "server role. <b>Backup Domain Controller</b> and <b>Primary Domain Controller</b> allow Windows clients to log in to a Windows domain. The backup controller \n" +
            "uses another domain controller for validation. The primary controller\n" +
            "uses its own information about users and their passwords.\n" +
            "If the server should not participate as a domain controller, choose the\n" +
            "<b>Not a DC</b> value.</p>\n"
        ),
        # Samba role dialog help 2/5
        "smb_conf_tab_base_settings_no_bdc"   => _(
          "<p>The <b>Base Settings</b> set up the domain and the\n" +
            "server role. <b>Primary Domain Controller</b> allows Windows clients\n" +
            "to log in to a Windows domain. If the server should not participate\n" +
            "as a domain controller, choose <b>Not a DC</b>.</p>\n"
        ),
        # Samba role dialog help 3/5
        "smb_conf_tab_wins_settings"          => _(
          "<p><b>WINS</b> is a network protocol for mapping low-level\n" +
            "network identification of a host (for example, IP address) to\n" +
            "a NetBIOS name. The Samba server can be a \n" +
            "WINS server or can use another server for its\n" +
            "queries. In the latter case, choose <b>Remote WINS Server</b>\n" +
            "and enter the IP address of the WINS server.</p>\n"
        ),
        # Samba role dialog help 4/5
        "smb_conf_tab_netbios_name"           => _(
          "<p>Optionally, set a <b>Server NetBIOS Name</b>. The\nNetBIOS name is the name the server uses in the SMB network.</p>"
        ),
        # Samba role dialog help 5/5
        "smb_conf_tab_advanced_settings"      => _(
          "<p><b>Advanced Settings</b> provides access to \ndetailed configuration, user authentication sources, and expert global settings.</p>\n"
        ),
        "smb_conf_tab_trusted_domains"        => _(
          "<p><b><big>Trusted Domains</big></b><br>\n" +
            "NT-style trusted domains represent a possibility to assign\n" +
            "access rights to users from another domain.\n" +
            "Here, create a list of domains for which \n" +
            "the Samba server should provide access.</p>\n"
        ) +
          _(
            "<p>To add a new domain into the list, press <b>Add</b>.\n" +
              "Enter the name of the domain to trust\n" +
              "and a password in the dialog that opens. The password is used by the Samba\n" +
              "server to access the trusted domain. After <b>OK</b> is pressed,\n" +
              "the trust relationship is established. To delete a domain,\n" +
              "choose it in the list and press <b>Delete</b>.</p>\n"
          ) +
          _(
            "<p>For more details about how trusted domains work,\nsee the Samba HOWTO collection.</p>\n"
          ),
        # Single share editing dialog help 1/2
        "share_edit"                          => _(
          "<p><b><big>Edit a Share</big></b><br>\nHere, fine-tune the options of a share.</p>\n"
        ) +
          # Single share editing dialog help 2/2
          _(
            "<p>Use <b>Add</b> to add a new configuration option, <b>Edit</b> to modify\nan existing option, and <b>Delete</b> to delete an option.</p>\n"
          ),
        # Global settings editing dialog help 1/2
        "global_settings"                     => _(
          "<p><b><big>Expert Global Settings Configuration</big></b><br>\nHere, fine-tune the global options of the server.</p>\n"
        ) +
          # Global settings editing dialog help 2/2
          _(
            "<p>Use <b>Add</b> to add a new configuration option, <b>Edit</b> to modify\nalready existing option, and <b>Delete</b> to delete an option.</p>\n"
          ),
        # Advanced SAMBA configuration dialog help 1/3
        "Advanced"                            => _(
          "<p><b><big>LDAP Samba Server Options</big></b><br>\n" +
            "Here, set up details about use of LDAP by the Samba\n" +
            "server.</p>\n"
        ) +
          # Advanced SAMBA configuration dialog help 2/3
          _(
            "<p><b>Search Base DN</b> (distinguished name) is\n" +
              "the base at which to start searching the information. <b>Administration DN</b> is used when\n" +
              "creating new users and groups. If the administration DN requires\n" +
              "a password for write access, set the password using\n" +
              "<b>Set LDAP Administration Password</b>.</p>\n"
          ) +
          # Advanced SAMBA configuration dialog help 3/3
          _(
            "<p><b>Note:</b> Settings are saved before the LDAP administration password is set.</p>\n"
          ),
        # passdb backend configuration dialog help 1
        "passdb_edit"                         => _(
          "<p><b><big>User Authentication Information Backends</big></b><br>\n" +
            "Choose where the Samba server should look for the authentication\n" +
            "information. Samba does not support multiple backends at once anymore,\n" +
            "only one is allowed.</p>\n"
        ) +
          # passdb backend configuration dialog help 2
          _(
            "<p>If you want to change the user authentication source, remove the current one first\nby pressing <b>Delete</b> and add a new one with <b>Add</b>.</p>\n"
          ) +
          # passdb backend configuration dialog help 3
          _(
            "<p><b>smbpasswd file</b> is the file using the same format as\n" +
              "the previous versions of Samba. Its layout is similar to the\n" +
              "passwd file. It is possible to have a multiple files in this \n" +
              "format.</p>\n"
          ) +
          # passdb backend configuration dialog help 4
          _(
            "<p><b>LDAP</b> is a URL of an LDAP server to check for\nthe information.</p>\n"
          ) +
          # passdb backend configuration dialog help 5
          _(
            "<p><b>TDB database</b> uses an internal Samba database binary format\nto store and look up the information.</p>\n"
          ),
        # we don't seem to support mysql anymore
        #    /* passdb backend configuration dialog help 5/7 */
        #_("<p><b>MySQL database</b> uses an external MySQL database to
        #to store and look up the information.</p>
        #") +

        # not in UI anymore
        # passdb backend configuration dialog help 6/7
        #_("<p>Use <b>Add</b> to add a new configuration option, <b>Edit</b> to modify
        #an existing option, and <b>Delete</b> to delete an option.
        #Use <b>Up</b> and <b>Down</b> to change the order
        #of the back-ends.</p>
        #"),

        # no such button there
        #    /* passdb backend configuration dialog help 7/7 */
        #_("<p>The <b>LDAP</b> button gives access to
        #details of an LDAP configuration and also allows
        #checking a connection to an LDAP server for the currently
        #selected LDAP back-end.</p>
        #"),

        # add new share dialog help 1/3
        "add_share"                           => _(
          "<p><b><big>Add a New Share</big></b><br>\nHere, enter the basic information about a share to add.</p>\n"
        ) +
          # add new share dialog help 2/3
          _(
            "<p><b>Share Name</b> is used for accessing\n" +
              "the share from clients. <b>Share Description</b> describes the\n" +
              "purpose of the share.</p>"
          ) +
          # add new share dialog help 3/3
          _(
            "<p>There are two types of shares. A <b>Printer</b> share\n" +
              "is presented as a printer to clients. A <b>Directory</b> share \n" +
              "is presented as a network disk. <b>Share Path</b> must be\n" +
              "entered for a directory share.</p>\n"
          ) +
          # add new share dialog help 4/3
          _(
            "<p>If <b>Read-Only</b> is checked, users\n" +
              "of a service may not create or modify files in the service's\n" +
              "directory.</p>\n"
          ) +
          _(
            "<p><b>Inherit ACLS</b> can be used to ensure\n" +
              "that if default ACLs exist on parent directories, they are always\n" +
              "honored when creating a subdirectory.</p>\n"
          ),
        # help for LDAP Settings dialog
        "samba_ldap_setting_auth_widget"      => _(
          "<p><b><big>LDAP Settings</big></b><br>\n" +
            "Here, determine the LDAP server to use for authentication.\n" +
            "</p>\n" +
            "<p>\n" +
            "Setting <b>LDAP Password Back-End</b> allows storing user information in the LDAP tree specified by the URL. With <b>LDAP Idmap Back-End</b>, store SID/uid/gid mapping tables in LDAP.\n" +
            "</p><p>\n" +
            "In the Authentication section, set the credentials for the LDAP server, including full Administrator DN.\n" +
            "</p>\n" +
            "<b>Search Base DN</b> is the LDAP suffix appended to Samba-specific LDAP objects.\n" +
            "</p><p>\n" +
            "To test the connection to your LDAP server, click <b>Test Connection</b>. To set expert LDAP settings or use default values, click <b>Advanced Settings</b>.<p>"
        ),
        # help for SambaLDAPSettingsSuffixesWidget
        "samba_ldap_setting_suffixes_widget"  => _(
          "<p><b>User Suffix</b> specifies where users are added to the LDAP tree. The value is pre-pended to the value of <b>Search Base DN</b>. Similarly, <b>Group Suffix</b> specifies the place for groups, <b>Machine Suffix</b> for machines and <b>Idmap Suffix</b> for idmap mappings.</p>"
        ),
        # help for SambaLDAPSettingsTimeoutsWidget
        "samba_ldap_settings_timeouts_widget" => _(
          "<p><b>Replication Sleep</b> is the amount of milliseconds Samba will wait after writing to the LDAP server, so LDAP replicas can catch up.</p>\n<p><b>Time-Out</b> specifies the timeout for LDAP operations (in seconds).</p>"
        ),
        # help for SambaLDAPSettingsSecurityWidget
        "samba_ldap_settings_security_widget" => _(
          "<p>Define whether to use SSL for LDAP connection with <b>Use SSL or TLS</b>.</p>"
        ),
        # help for SambaLDAPSettingsMiscWidget
        "samba_ldap_settings_misc_widget"     => _(
          "<p><b>Delete DN</b> specifies if the delete operation deletes the complete LDAP entry or only the Samba-specific attributes.</p>\n<p>With <b>Synchronize Passwords</b>, define possible synchronization of the LDAP password with the NT and LM hashes. See the <tt>smb.conf</tt> manual page for details.</p>"
        )
      }

      @warnings = {
        # translators: warning text
        "netbios" => _(
          "If you change the NetBIOS Hostname, Samba creates a\n" +
            "service identifier (SID) for your server with the first client\n" +
            "connection.  Because the new SID is not equal to the old one, clients can\n" +
            "no longer authenticate as domain members.\n"
        ),
        # translators: warning text
        "/tmp"    => _(
          "Consider that /tmp and /var/tmp are publicly accessible\n" +
            "directories and a scheduled clean job might remove files after a\n" +
            "configured period. See MAX_DAYS_IN_TMP and TMP_DIRS_TO_CLEAR in\n" +
            "/etc/sysconfig/cron.\n"
        ),
        # translators: warning text
        "/var"    => _(
          "Exporting /var might lead to security problems. The\ndirectory includes many secrets of your system.\n"
        ),
        # translators: warning text
        "/etc"    => _(
          "Exporting /etc might lead to security problems. The\ndirectory includes many secrets of your system.\n"
        )
      }

      # translators: warning text
      @root_warning = _(
        "Exporting / might lead to security problems because it makes your\nentire file system browsable from Samba clients.\n"
      )

      @obsolete = _(
        "<p><b>Advanced Settings</b> provides access to \n" +
          "detailed configuration, such as LDAP settings, user authentication sources, and\n" +
          "expert global settings.</p>\n"
      ) 

      # EOF
    end
  end
end
