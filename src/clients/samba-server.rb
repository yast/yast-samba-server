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

# File:	clients/samba-server.ycp
# Package:	Configuration of samba-server
# Summary:	Main file
# Authors:	Stanislav Visnovsky <visnov@suse.cz>
#
# $Id$
#
# Main file for samba-server configuration. Uses all other files.

# TODO:
#  - Read/Write only needed modules (if command line is used)
#  - allow set more options on command line (ldap server, ...)
module Yast
  class SambaServerClient < Client
    def main
      Yast.import "UI"

      #**
      # <h3>Configuration of the samba-server</h3>

      textdomain "samba-server"

      Yast.import "CommandLine"
      Yast.import "Popup"
      Yast.import "Report"

      Yast.import "SambaRole"
      Yast.import "SambaServer"
      Yast.import "SambaConfig"
      Yast.import "SambaService"
      Yast.import "SambaBackend"

      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("Samba-server module started")

      Yast.include self, "samba-server/wizards.rb"

      # main ui function
      @ret = nil

      @cmdline = {
        "id"         => "samba-server",
        # translators: command line help text for samba-server module
        "help"       => _(
          "Samba server configuration module (see Samba documentation for details)"
        ),
        "guihandler" => fun_ref(method(:SambaServerSequence), "any ()"),
        "initialize" => fun_ref(SambaServer.method(:Read), "boolean ()"),
        "finish"     => fun_ref(SambaServer.method(:Write), "boolean (boolean)"),
        "actions"    => {
          "share"     => {
            "handler" => fun_ref(
              method(:ShareHandler),
              "boolean (map <string, string>)"
            ),
            # translators: command line help text for share action
            "help"    => _(
              "Manipulate a single share"
            )
          },
          "list"      => {
            "handler" => fun_ref(
              method(:ListHandler),
              "boolean (map <string, string>)"
            ),
            # translators: command line help text for list action
            "help"    => _(
              "Show the list of available shares"
            )
          },
          "role"      => {
            "handler" => fun_ref(
              method(:RoleHandler),
              "boolean (map <string, string>)"
            ),
            # translators: command line help text for role action
            "help"    => _(
              "Set the role of the server"
            )
          },
          "backend"   => {
            "handler" => fun_ref(
              method(:BackendHandler),
              "boolean (map <string, string>)"
            ),
            # translators: command line help text for backend selection action
            "help"    => _(
              "Set the back-end for storing user information"
            )
          },
          "service"   => {
            "handler" => fun_ref(
              method(:SambaServerEnableHandler),
              "boolean (map <string, string>)"
            ),
            # translators: command line help text for service activation action
            "help"    => _(
              "Enable or disable the Samba services (smb and nmb)"
            )
          },
          "configure" => {
            "handler" => fun_ref(
              method(:ChangeConfiguration),
              "boolean (map <string, string>)"
            ),
            # translators: command line help text for configure action
            "help"    => _(
              "Change the global settings of the Samba server"
            )
          }
        },
        "options"    => {
          "enable"        => {
            # translators: command line help text for enable option
            "help" => _(
              "Enable the share or a service"
            )
          },
          "disable"       => {
            # translators: command line help text for disable option
            "help" => _(
              "Disable the share or a service"
            )
          },
          "delete"        => {
            # translators: command line help text for delete share option
            "help" => _(
              "Remove the share from the configuration file"
            )
          },
          "name"          => {
            # translators: command line help text for share name option
            "help" => _(
              "The name of a share"
            ),
            "type" => "string"
          },
          "add"           => {
            # translators: command line help text for "share add" subaction
            "help" => _(
              "Add a new share"
            )
          },
          "options"       => {
            # translators: command line help text for "share options" subaction
            "help" => _(
              "Change options of a share"
            )
          },
          "show"          => {
            # translators: command line help text for "share show" subaction
            "help" => _(
              "Show the options of a share"
            )
          },
          "comment"       => {
            # translators: command line help text for share comment option
            "help" => _(
              "The comment of a share"
            ),
            "type" => "string"
          },
          "path"          => {
            # translators: command line help text for share path option
            "help" => _(
              "The path (directory) to share"
            ),
            "type" => "string"
          },
          "printable"     => {
            # translators: command line help text for share printable option
            "help" => _(
              "Flag if the share should act as a printer"
            ),
            "type" => "boolean"
          },
          "read_list"     => {
            # translators: command line help text for share read_list option
            "help" => _(
              "A comma-separated list of users allowed to read from the share"
            ),
            "type" => "string"
          },
          "write_list"    => {
            # translators: command line help text for share write_list option
            "help" => _(
              "A comma-separated list of users allowed to write to the share"
            ),
            "type" => "string"
          },
          "browseable"    => {
            # translators: command line help text for share browseable option
            "help" => _(
              "Flag if the share should be visible when browsing the LAN"
            ),
            "type" => "boolean"
          },
          "guest_ok"      => {
            # translators: command line help text for share guest_ok option
            "help" => _(
              "Flag if the share should allow guest access"
            ),
            "type" => "boolean"
          },
          "valid_users"   => {
            # translators: command line help text for share valid_users option
            "help" => _(
              "A comma-separated list of users allowed to access the share"
            ),
            "type" => "string"
          },
          "pdc"           => {
            # translators: command line help text for PDC role option
            "help" => _(
              "Server should act as a primary domain controller"
            )
          },
          "bdc"           => {
            # translators: command line help text for BDC role option
            "help" => _(
              "Server should act as a backup domain controller"
            )
          },
          "member"        => {
            # translators: command line help text for Domain Member role option
            "help" => _(
              "Server should act as a domain member"
            )
          },
          "standalone"    => {
            # translators: command line help text for standalone server role option
            "help" => _(
              "Server should provide shares, but should not allow domain logins"
            )
          },
          "smbpasswd"     => {
            # translators: command line help text for smbpasswd option
            "help" => _(
              "Use the 'smbpasswd' file to store user information"
            )
          },
          "tdbsam"        => {
            # translators: command line help text for tdbsam option
            "help" => _(
              "Use the 'passdb.tdb' file to store user information"
            )
          },
          "ldapsam"       => {
            # translators: command line help text for ldapsam option
            "help" => _(
              "Use the LDAP server to store user information"
            )
          },
          "password"      => {
            # translators: command line help text for password option
            "help" => _(
              "Password for the LDAP server"
            )
          },
          "workgroup"     => {
            # translators: command line help text for workgroup option
            "help" => _(
              "The name of a workgroup"
            ),
            "type" => "string"
          },
          "description"   => {
            # translators: command line help text for description option
            "help" => _(
              "The human-readable description of the Samba server"
            ),
            "type" => "string"
          },
          "ldap_suffix"   => {
            # translators: command line help text for ldap_suffix option
            "help" => _(
              "The LDAP suffix DN for manipulating the user information on the LDAP server"
            ),
            "type" => "string"
          },
          "ldap_admin_dn" => {
            # translators: command line help text for ldap_admin_dn option
            "help" => _(
              "The LDAP DN for modifying contents of the LDAP server (for example, changing passwords)"
            ),
            "type" => "string"
          }
        },
        "mappings"   => {
          "share"     => [
            "enable",
            "disable",
            "delete",
            "add",
            "options",
            "show",
            "name",
            "comment",
            "path",
            "printable",
            "read_list",
            "write_list",
            "browseable",
            "guest_ok",
            "valid_users"
          ],
          "list"      => [],
          "role"      => ["pdc", "bdc", "standalone", "member"],
          "backend"   => ["smbpasswd", "tdbsam", "ldapsam"],
          "service"   => ["enable", "disable"],
          "configure" => [
            "workgroup",
            "description",
            "ldap_suffix",
            "ldap_admin_dn"
          ]
        }
      }

      @ret = CommandLine.Run(@cmdline)

      Builtins.y2debug("ret=%1", @ret)

      # Finish
      Builtins.y2milestone("Samba-server module finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret) 

      # EOF
    end

    # Command line "share" commands handler.
    #
    # @param [Hash{String => String}] options	map of options from command line
    # @return [Boolean]	true on success
    def ShareHandler(options)
      options = deep_copy(options)
      share = Ops.get(options, "name")

      # check the "command" to be present exactly once
      command = CommandLine.UniqueOption(
        options,
        ["add", "delete", "enable", "disable", "options", "show"]
      )
      return false if command == nil

      # validate the options
      if share == nil
        # translators: error message for share command line action
        # must provide the share name
        Report.Error(_("Specify the share name."))
        return false
      end

      if !SambaConfig.ShareExists(share) && command != "add"
        # translators: error message for "share add" command line action, %1 is share name
        Report.Error(Builtins.sformat(_("The share %1 does not exist."), share))
        return false
      end

      # process the commands
      if command == "enable"
        SambaConfig.ShareEnable(share)
      elsif command == "disable"
        SambaConfig.ShareDisable(share)
      elsif command == "delete"
        SambaConfig.ShareRemove(share)
      elsif command == "add"
        if !Builtins.haskey(options, "path")
          # translators: error message for "add share" command line action
          Report.Error(_("Provide the path of a directory to share."))
          return false
        end

        if SambaConfig.ShareExists(share)
          # translators: error message for "add share" command line action, %1 is share name
          Report.Error(Builtins.sformat(_("Share %1 already exists."), share))
          return false
        end
        SambaConfig.ShareSetStr(share, "path", Ops.get(options, "path", ""))
        SambaConfig.ShareSetStr(
          share,
          "comment",
          Ops.get(
            options,
            "comment",
            Builtins.sformat("Share for %1", Ops.get(options, "path", "path"))
          )
        )
      elsif command == "show"
        CommandLine.Print(Builtins.sformat("[%1]", share))

        Builtins.foreach(SambaConfig.ShareGetMap(share)) do |key, val|
          if val != nil
            CommandLine.Print(Builtins.sformat("\t%1 = %2", key, val))
          end
        end
      elsif command == "options"
        Builtins.foreach(
          [
            "comment",
            "path",
            "printable",
            "write list",
            "browseable",
            "guest ok",
            "valid users"
          ]
        ) do |key|
          value = Ops.get(options, key)
          SambaConfig.ShareSetStr(share, key, value) if value != nil
        end
      end

      true
    end

    # Command line "list" command handler.
    #
    # @param [Hash{String => String}] options	map of options from command line
    # @return [Boolean]	true on success
    def ListHandler(options)
      options = deep_copy(options)
      # translators: heading for "list" shares command line action
      # try to keep alignment
      CommandLine.Print(
        _("Status  \tType\tName\n==============================")
      )

      printers = {}

      Builtins.foreach(SambaConfig.GetShares) do |share|
        if !SambaConfig.ShareGetTruth(share, "printable", false)
          # translators: share is a disk. %1 is the status, %2 comment
          CommandLine.Print(
            Builtins.sformat(
              _("%1\tDisk\t%2"),
              (# translators: share status
              SambaConfig.ShareEnabled(share) ?
                _("Disabled") :
                # translators: share status
                _("Enabled")) + "  ",
              share
            )
          )
        end
      end


      Builtins.foreach(SambaConfig.GetShares) do |share|
        if SambaConfig.ShareGetTruth(share, "printable", false)
          # translators: share is a printer. %1 is the status, %2 comment
          CommandLine.Print(
            Builtins.sformat(
              _("%1\tPrinter\t%2"),
              (SambaConfig.ShareEnabled(share) ?
                # translators: share status
                _("Disabled") :
                # translators: share status
                _("Enabled")) + "  ",
              share
            )
          )
        end
      end

      true
    end

    # Command line "backend" command handler.
    #
    # @param [Hash{String => String}] options	map of options from command line
    # @return [Boolean]	true on success
    def BackendHandler(options)
      options = deep_copy(options)
      command = CommandLine.UniqueOption(
        options,
        ["smbpasswd", "tdbsam", "ldapsam"]
      )
      return false if command == nil
      SambaBackend.SetPassdbBackends([command])
      true
    end

    # Command line "role" command handler.
    #
    # @param [Hash{String => String}] options	map of options from command line
    # @return [Boolean]	true on success
    def RoleHandler(options)
      options = deep_copy(options)
      # check the role to be present exactly once
      command = CommandLine.UniqueOption(
        options,
        ["pdc", "bdc", "standalone", "member"]
      )
      return false if command == nil
      SambaRole.SetRole(command)
      true
    end

    # Command line "service" command handler.
    #
    # @param [Hash{String => String}] options	map of options from command line
    # @return [Boolean]	true on success
    def SambaServerEnableHandler(options)
      options = deep_copy(options)
      # check the "command" to be present exactly once
      command = CommandLine.UniqueOption(options, ["enable", "disable"])
      return false if command == nil
      SambaService.SetServiceAutoStart(command == "enable")
      true
    end

    # Command line "configure" command handler.
    #
    # @param [Hash{String => String}] options	map of options from command line
    # @return [Boolean]	true on success
    def ChangeConfiguration(options)
      options = deep_copy(options)
      value = Ops.get(options, "workgroup")
      SambaConfig.GlobalSetStr("workgroup", value) if value != nil

      value = Ops.get(options, "description")
      SambaConfig.GlobalSetStr("server string", value) if value != nil

      value = Ops.get(options, "ldap_suffix")
      SambaConfig.GlobalSetStr("ldap suffix", value) if value != nil

      value = Ops.get(options, "ldap_admin_dn")
      SambaConfig.GlobalSetStr("ldap admin dn", value) if value != nil

      true
    end
  end
end

Yast::SambaServerClient.new.main
