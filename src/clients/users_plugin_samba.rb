# encoding: utf-8

# File:
#	users_plugin_samba.ycp
#
# Package:
#	Configuration of Users
#
# Summary:
#	This is part GUI of UsersPluginSamba - plugin for editing all LDAP
#	user/group attributes.
#
# $Id$
module Yast
  class UsersPluginSambaClient < Client
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
      Yast.import "UsersPluginSamba" # plugin module

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
        @ret = UsersPluginSamba.Summary(@config, {})
      elsif @func == "Name"
        @ret = UsersPluginSamba.Name(@config, {})
      elsif @func == "Dialog"
        # define the dialog for this plugin and return it's contents

        @caption = UsersPluginSamba.Name(@config, {})

        # helptext
        @help_text = _(
          "<p>Here, edit the setting of the user's samba account.</p>"
        ) +
          _("<p>If do not enter custom values for ") +
          _(
            "<b>Home Drive</b>, <b>Home Path</b>, <b>Profile Path</b>, and <b>Logon Script</b> "
          ) +
          _(
            "the default values as defined in your local Samba Configuration will be used.</p>"
          )

        @contents = Empty()
        @disabled = false
        @noExpire = false

        @noExpire = Ops.get_string(@data, "sambanoexpire", "0") == "1" ? true : false
        @disabled = Ops.get_string(@data, "sambadisabled", "0") == "1" ? true : false
        @contents = HBox(
          HSpacing(1.5),
          VBox(
            VSpacing(0.5),
            Frame(
              _("Home Drive"),
              VBox(
                TextEntry(
                  Id(:homeDrive),
                  "",
                  Ops.get_string(@data, "sambaHomeDrive", "")
                ),
                Left(
                  CheckBox(
                    Id(:defhomeDrive),
                    Opt(:notify),
                    _("Use Default Values"),
                    Ops.less_or_equal(
                      Builtins.size(Ops.get_string(@data, "sambaHomeDrive", "")),
                      0
                    )
                  )
                )
              )
            ),
            Frame(
              _("Home Path"),
              VBox(
                TextEntry(
                  Id(:homePath),
                  "",
                  Ops.get_string(@data, "sambaHomePath", "")
                ),
                Left(
                  CheckBox(
                    Id(:defhomePath),
                    Opt(:notify),
                    _("Use Default Values"),
                    Ops.less_or_equal(
                      Builtins.size(Ops.get_string(@data, "sambaHomePath", "")),
                      0
                    )
                  )
                )
              )
            ),
            Frame(
              _("Profile Path"),
              VBox(
                TextEntry(
                  Id(:profilePath),
                  "",
                  Ops.get_string(@data, "sambaProfilePath", "")
                ),
                Left(
                  CheckBox(
                    Id(:defprofilePath),
                    Opt(:notify),
                    _("Use Default Values"),
                    Ops.less_or_equal(
                      Builtins.size(
                        Ops.get_string(@data, "sambaProfilePath", "")
                      ),
                      0
                    )
                  )
                )
              )
            ),
            # translators: logon is the Windows synonym for login
            Frame(
              _("Logon Script"),
              VBox(
                TextEntry(
                  Id(:logonScript),
                  "",
                  Ops.get_string(@data, "sambaLogonScript", "")
                ),
                Left(
                  CheckBox(
                    Id(:deflogonScript),
                    Opt(:notify),
                    _("Use Default Values"),
                    Ops.less_or_equal(
                      Builtins.size(
                        Ops.get_string(@data, "sambaLogonScript", "")
                      ),
                      0
                    )
                  )
                )
              )
            ),
            VSpacing(1.5),
            Left(CheckBox(Id(:disable), _("Samba Account Disabled"), @disabled)),
            Left(
              CheckBox(Id(:noExpire), _("No Password Expiration"), @noExpire)
            ),
            VSpacing(0.5)
          ),
          HSpacing(1.5)
        )

        Wizard.CreateDialog
        Wizard.SetDesktopIcon("org.openSUSE.YaST.SambaServer")

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
          UI.ChangeWidget(
            Id(:homeDrive),
            :Enabled,
            !Convert.to_boolean(UI.QueryWidget(Id(:defhomeDrive), :Value))
          )
          UI.ChangeWidget(
            Id(:homePath),
            :Enabled,
            !Convert.to_boolean(UI.QueryWidget(Id(:defhomePath), :Value))
          )
          UI.ChangeWidget(
            Id(:profilePath),
            :Enabled,
            !Convert.to_boolean(UI.QueryWidget(Id(:defprofilePath), :Value))
          )
          UI.ChangeWidget(
            Id(:logonScript),
            :Enabled,
            !Convert.to_boolean(UI.QueryWidget(Id(:deflogonScript), :Value))
          )

          @ret = UI.UserInput
          if @ret == :next
            @err = UsersPluginSamba.Check(@config, @data)
            if Convert.to_boolean(UI.QueryWidget(Id(:defhomeDrive), :Value))
              Ops.set(@data, "sambaHomeDrive", "")
            else
              Ops.set(
                @data,
                "sambaHomeDrive",
                UI.QueryWidget(Id(:homeDrive), :Value)
              )
            end
            if Convert.to_boolean(UI.QueryWidget(Id(:defhomePath), :Value))
              Ops.set(@data, "sambaHomePath", "")
            else
              Ops.set(
                @data,
                "sambaHomePath",
                UI.QueryWidget(Id(:homePath), :Value)
              )
            end
            if Convert.to_boolean(UI.QueryWidget(Id(:defprofilePath), :Value))
              Ops.set(@data, "sambaProfilePath", "")
            else
              Ops.set(
                @data,
                "sambaProfilePath",
                UI.QueryWidget(Id(:profilePath), :Value)
              )
            end
            if Convert.to_boolean(UI.QueryWidget(Id(:deflogonScript), :Value))
              Ops.set(@data, "sambaLogonScript", "")
            else
              Ops.set(
                @data,
                "sambaLogonScript",
                UI.QueryWidget(Id(:logonScript), :Value)
              )
            end
            Ops.set(
              @data,
              "sambanoexpire",
              UI.QueryWidget(Id(:noExpire), :Value) == true ? "1" : "0"
            )
            Ops.set(
              @data,
              "sambadisabled",
              UI.QueryWidget(Id(:disable), :Value) == true ? "1" : "0"
            )
            if @err != ""
              Report.Error(@err)
              @ret = :notnext
              next
            end

            # if this plugin wasn't in default set, we must save its name
            if !Builtins.contains(
                Ops.get_list(@data, "plugins", []),
                "UsersPluginSamba"
              )
              Ops.set(
                @data,
                "plugins",
                Builtins.add(
                  Ops.get_list(@data, "plugins", []),
                  "UsersPluginSamba"
                )
              )
            end
            if Ops.get_string(@data, "what", "") == "edit_user"
              Users.EditUser(@data)
            elsif Ops.get_string(@data, "what", "") == "add_user"
              Users.AddUser(@data)
            elsif Ops.get_string(@data, "what", "") == "edit_group"
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
      Builtins.y2milestone("users plugin finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret)
    end
  end
end

Yast::UsersPluginSambaClient.new.main
