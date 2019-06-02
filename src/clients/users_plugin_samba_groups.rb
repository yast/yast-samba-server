# encoding: utf-8

# File:
#	users_plugin_ldap_all.ycp
#
# Package:
#	Configuration of Users
#
# Summary:
#	This is part GUI of UsersPluginSambaGroups - plugin for editing all LDAP
#	attributes for Samba groups.
#
# $Id$
module Yast
  class UsersPluginSambaGroupsClient < Client
    def main
      Yast.import "UI"
      textdomain "samba-users" # use own textdomain for new plugins

      Yast.import "Label"
      Yast.import "Popup"
      Yast.import "Report"
      Yast.import "Wizard"

      Yast.import "Ldap"
      Yast.import "LdapPopup"
      Yast.import "Users"
      Yast.import "UsersLDAP"
      Yast.import "UsersPluginSambaGroups" # plugin module

      @ret = nil
      @func = ""
      @config = {}
      @data = {}

      # Check arguments
      if Ops.greater_than(Builtins.size(WFM.Args), 0) &&
          Ops.is_string?(WFM.Args(0))
        @func = Convert.to_string(WFM.Args(0))
        if Ops.greater_than(Builtins.size(WFM.Args), 1) &&
            Ops.is_map?(WFM.Args(1))
          @config = Convert.convert(
            WFM.Args(1),
            :from => "any",
            :to   => "map <string, any>"
          )
        end
        if Ops.greater_than(Builtins.size(WFM.Args), 2) &&
            Ops.is_map?(WFM.Args(2))
          @data = Convert.convert(
            WFM.Args(2),
            :from => "any",
            :to   => "map <string, any>"
          )
        end
      end
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("users plugin started: Samba")

      Builtins.y2debug("func=%1", @func)
      Builtins.y2debug("config=%1", @config)
      Builtins.y2debug("data=%1", @data)

      if @func == "Summary"
        @ret = UsersPluginSambaGroups.Summary(@config, {})
      elsif @func == "Name"
        @ret = UsersPluginSambaGroups.Name(@config, {})
      elsif @func == "Dialog"
        # define the dialog for this plugin and return it's contents

        @caption = UsersPluginSambaGroups.Name(@config, {})
        if Ops.get_string(@data, "what", "") == "edit_group"
          @data = UsersPluginSambaGroups.EditBefore(@config, @data)
        elsif Ops.get_string(@data, "what", "") == "add_group"
          @data = UsersPluginSambaGroups.AddBefore(@config, @data)
        end



        @help_text =
          # help text
          _(
            "<p>This plugin can be used to enable an LDAP group to be available for Samba.\n" +
              "The only setting that you can edit here is the <b>Samba Group Name</b> attribute,\n" +
              "which is the Name of the Group as it should appear to Samba-Clients. All other\n" +
              "settings are computed automatically. If you leave the <b>Samba Group Name</b>\n" +
              "empty, the same name as configured in the Global Settings of this Group will\n" +
              "be used.</p>\n"
          )

        @contents = Empty()

        @contents = HBox(
          HSpacing(1.5),
          VBox(
            VSpacing(0.5),
            TextEntry(
              Id(:smbName),
              _("Samba Group Name"),
              Ops.get_string(@data, "displayName", "")
            ),
            VSpacing(0.5)
          ),
          HSpacing(1.5)
        )

        Wizard.CreateDialog
        Wizard.SetDesktopIcon("org.opensuse.yast.SambaServer")

        # dialog caption
        Wizard.SetContentsButtons(
          _("Edit Samba Attributes"),
          @contents,
          @help_text,
          Label.BackButton,
          Label.NextButton
        )

        Wizard.HideAbortButton

        @ret = :next
        begin
          @ret = UI.UserInput
          if @ret == :next
            @err = UsersPluginSambaGroups.Check(@config, @data)
            Ops.set(@data, "displayName", UI.QueryWidget(Id(:smbName), :Value))
            if @err != ""
              Report.Error(@err)
              @ret = :notnext
              next
            end

            # if this plugin wasn't in default set, we must save its name
            if !Builtins.contains(
                Ops.get_list(@data, "plugins", []),
                "UsersPluginSambaGroups"
              )
              Ops.set(
                @data,
                "plugins",
                Builtins.add(
                  Ops.get_list(@data, "plugins", []),
                  "UsersPluginSambaGroups"
                )
              )
            end

            if Ops.get_string(@data, "what", "") == "edit_group"
              Users.EditGroup(@data)
            elsif Ops.get_string(@data, "what", "") == "add_group"
              Users.AddGroup(@data)
            end
          end
        end until Ops.is_symbol?(@ret) &&
          Builtins.contains(
            [:next, :abort, :back, :cancel],
            Convert.to_symbol(@ret)
          )

        Wizard.CloseDialog
      else
        Builtins.y2error("unknown function: %1", @func)
        @ret = false
      end

      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("groups plugin finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret)
    end
  end
end

Yast::UsersPluginSambaGroupsClient.new.main
