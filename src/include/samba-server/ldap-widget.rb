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

# File:	include/samba-server/ldap-widget.ycp
# Package:	Configuration of samba-server
# Summary:	Dialogs definitions
# Authors:	Martin Lazar <mlazar@suse.cz>
#		Lukas Ocilka <locilka@suse.cz>
#
# $Id$
#
# This file contains CWM widgets related to Samba LDAP Settings:
#  - Samba LDAP Settings Essential Widget
#  - Samba LDAP Settings Suffixes Widget
#  - Samba LDAP Settings Timeouts Widget
#  - Samba LDAP Settings Misc Widget
module Yast
  module SambaServerLdapWidgetInclude
    def initialize_samba_server_ldap_widget(include_target)
      Yast.import "UI"

      textdomain "samba-server"

      Yast.import "URL"
      Yast.import "Popup"

      Yast.import "CWM"
      Yast.import "Ldap"
      Yast.import "Label"
      Yast.import "Wizard"

      Yast.import "SambaConfig"
      Yast.import "SambaBackend"
      Yast.import "SambaBackendLDAP"

      Yast.include include_target, "samba-server/helps.rb"


      @widget_names = nil
      @widget_descr = nil

      # Samba LDAP Settings Security Widget
      #/////////////////////////////////////////////////////////////////////////

      # translators: combo box value
      @ldap_ssl_values = [
        ["Off", _("No")],
        # translators: combo box value
        ["Start_tls", _("TLS")]
      ]


      # Samba LDAP Settings Misc Widget
      #/////////////////////////////////////////////////////////////////////////

      # translators: combo box value
      @ldap_yes_no_values = [
        ["Yes", _("Yes")],
        # translators: combo box value
        ["No", _("No")]
      ]
      # translators: combo box value (updata password? Yes/No/Only = Only update the LDAP password and let the LDAP server do the rest)
      @ldap_yes_no_only_values = Convert.convert(
        Builtins.merge(@ldap_yes_no_values, [["Only", _("Only")]]),
        :from => "list",
        :to   => "list <list>"
      )
    end

    # helper functions

    def init_ldap_str(id)
      UI.ChangeWidget(
        Id(id),
        :Value,
        SambaConfig.GlobalGetStr(id, SambaBackendLDAP.GetSambaDefaultValue(id))
      )

      nil
    end

    def init_ldap_int(id)
      UI.ChangeWidget(
        Id(id),
        :Value,
        SambaConfig.GlobalGetInteger(
          id,
          Builtins.tointeger(SambaBackendLDAP.GetSambaDefaultValue(id))
        )
      )

      nil
    end

    def init_ldap_combo(id, m)
      m = deep_copy(m)
      val = Builtins.tolower(
        SambaConfig.GlobalGetStr(id, SambaBackendLDAP.GetSambaDefaultValue(id))
      )
      subid = nil
      Builtins.foreach(
        Convert.convert(m, :from => "list", :to => "list <list>")
      ) do |l|
        if subid == nil
          if Builtins.tolower(Ops.get_string(l, 0, "")) == val
            subid = Ops.get_string(l, 0, "")
          end
        end
      end
      UI.ChangeWidget(Id(id), :Value, subid)

      nil
    end

    def store_ldap_str(id)
      val = Convert.to_string(UI.QueryWidget(Id(id), :Value))
      # do not store default values
      if val == SambaBackendLDAP.GetSuseDefaultValue(id) &&
          val == SambaBackendLDAP.GetSambaDefaultValue(id)
        val = nil
      end
      SambaConfig.GlobalSetStr(id, val)

      nil
    end

    def store_ldap_int(id)
      val = Builtins.tostring(
        Convert.to_integer(UI.QueryWidget(Id(id), :Value))
      )
      # do not store default values
      if val == SambaBackendLDAP.GetSuseDefaultValue(id) &&
          val == SambaBackendLDAP.GetSambaDefaultValue(id)
        val = nil
      end
      SambaConfig.GlobalSetStr(id, val)

      nil
    end


    # Samba LDAP Settings Essential Widget
    #////////////////////////////////////////////////////////////////////

    def _try_connect(url, admin_dn, passwd)
      if url == ""
        # translators: popup warning message about empty text entry
        Popup.Warning(_("Enter the server URL."))
        return false
      end
      err = SambaBackendLDAP.TryBind(url, admin_dn, passwd)
      if err != nil
        Ldap.LDAPErrorMessage("bind", err)
        return false
      end
      true
    end

    def SambaLDAPTryConnect
      passwd1 = Convert.to_string(UI.QueryWidget(Id(:passwd1), :Value))
      passwd2 = Convert.to_string(UI.QueryWidget(Id(:passwd2), :Value))
      if passwd1 != passwd2
        Popup.Warning(_("Passwords do not match."))
        UI.SetFocus(Id(:passwd1))
        return false
      end

      admin_dn = Convert.to_string(UI.QueryWidget(Id("ldap admin dn"), :Value))

      url = nil
      if Convert.to_boolean(
          UI.QueryWidget(Id(:ldap_passdb_backend_enable), :Value)
        )
        url = Convert.to_string(
          UI.QueryWidget(Id(:ldap_passdb_backend_url), :Value)
        )
        return false if !_try_connect(url, admin_dn, passwd1)
      end

      if Convert.to_boolean(
          UI.QueryWidget(Id(:ldap_idmap_backend_enable), :Value)
        )
        idmap_url = Convert.to_string(
          UI.QueryWidget(Id(:ldap_idmap_backend_url), :Value)
        )
        if url != idmap_url
          return false if !_try_connect(idmap_url, admin_dn, passwd1)
        end
      end

      true
    end


    def SambaLDAPSettingsEssentialWidgetInit(key)
      init_ldap_str("ldap suffix")

      init_ldap_str("ldap admin dn")
      UI.ChangeWidget(Id(:passwd1), :Value, SambaBackendLDAP.GetAdminPassword)
      UI.ChangeWidget(Id(:passwd2), :Value, SambaBackendLDAP.GetAdminPassword)

      passdb_url = SambaBackendLDAP.GetPassdbServerUrl
      UI.ChangeWidget(
        Id(:ldap_passdb_backend_url),
        :Value,
        passdb_url == nil ? "" : URL.Build(passdb_url)
      )
      UI.ChangeWidget(Id(:ldap_passdb_backend_url), :Enabled, passdb_url != nil)
      UI.ChangeWidget(
        Id(:ldap_passdb_backend_enable),
        :Value,
        passdb_url != nil
      )

      idmap_url = SambaBackendLDAP.GetIdmapServerUrl
      UI.ChangeWidget(
        Id(:ldap_idmap_backend_url),
        :Value,
        idmap_url == nil ? "" : URL.Build(idmap_url)
      )
      UI.ChangeWidget(Id(:ldap_idmap_backend_url), :Enabled, idmap_url != nil)
      UI.ChangeWidget(Id(:ldap_idmap_backend_enable), :Value, idmap_url != nil)

      Builtins.foreach(
        [
          "ldap suffix",
          "ldap admin dn",
          :passwd1,
          :passwd2,
          :ldap_try_connect,
          :ldap_advanced_settings
        ]
      ) do |id|
        UI.ChangeWidget(Id(id), :Enabled, idmap_url != nil || passdb_url != nil)
      end

      UI.SetFocus(Id(:passwd1))

      nil
    end

    def ProposeDefaultValues
      SambaConfig.GlobalSetMap(SambaBackendLDAP.GetSuseDefaultValues)
      if Ldap.server != nil && Ldap.server != ""
        SambaConfig.GlobalSetStr(
          "idmap backend",
          Ops.add("ldap:ldap://", Ldap.GetFirstServer(Ldap.server))
        )
        SambaBackend.AddPassdbBackend(
          "ldapsam",
          Ops.add("ldap://", Ldap.GetFirstServer(Ldap.server))
        )
      else
        SambaConfig.GlobalSetStr("idmap backend", nil)
        SambaBackend.RemovePassdbBackend("ldapsam")
      end
      SambaLDAPSettingsEssentialWidgetInit(nil)

      nil
    end

    def SambaLDAPSettingsEssentialWidgetHandle(key, event_descr)
      event_descr = deep_copy(event_descr)
      id = Ops.get(event_descr, "ID")

      if id == :passwd1 || id == :passwd2
        passwd1 = Convert.to_string(UI.QueryWidget(Id(:passwd1), :Value))
        passwd2 = Convert.to_string(UI.QueryWidget(Id(:passwd2), :Value))
        if passwd1 != passwd2
          # translators: inform text
          UI.ReplaceWidget(
            Id("passwd_label"),
            Left(Label(_("Passwords do not match.")))
          )
          UI.ChangeWidget(Id(:ldap_try_connect), :Enabled, false)
          UI.SetFocus(Id(:passwd2))
        elsif passwd1 == SambaBackendLDAP.GetAdminPassword
          UI.ReplaceWidget(Id("passwd_label"), Left(Label("")))
          UI.ChangeWidget(Id(:ldap_try_connect), :Enabled, true)
        else
          # translators: inform text
          UI.ReplaceWidget(
            Id("passwd_label"),
            Left(Label(_("Passwords match.")))
          )
          UI.ChangeWidget(Id(:ldap_try_connect), :Enabled, true)
        end
      elsif id == :ldap_passdb_backend_enable ||
          id == :ldap_idmap_backend_enable
        passdb = Convert.to_boolean(
          UI.QueryWidget(Id(:ldap_passdb_backend_enable), :Value)
        )
        UI.ChangeWidget(Id(:ldap_passdb_backend_url), :Enabled, passdb)

        idmap = Convert.to_boolean(
          UI.QueryWidget(Id(:ldap_idmap_backend_enable), :Value)
        )
        UI.ChangeWidget(Id(:ldap_idmap_backend_url), :Enabled, idmap)

        Builtins.foreach(
          [
            "ldap suffix",
            "ldap admin dn",
            :passwd1,
            :passwd2,
            :ldap_try_connect,
            :ldap_advanced_settings
          ]
        ) { |id2| UI.ChangeWidget(Id(id2), :Enabled, idmap || passdb) }

        # Propose default values
        if passdb || idmap
          some_values_filled = false
          Builtins.foreach(
            [
              :passwd1,
              :passwd2,
              :ldap_passdb_backend_url,
              :ldap_passdb_backend_url,
              :ldap_idmap_backend_url,
              :ldap_idmap_backend_url
            ]
          ) do |ui_widget_setting|
            read_value = Convert.to_string(
              UI.QueryWidget(Id(ui_widget_setting), :Value)
            )
            if read_value != "" && read_value != nil
              some_values_filled = true
              raise Break
            end
          end

          if some_values_filled == false &&
              Popup.YesNo(
                _(
                  "All current LDAP-related values will be rewritten.\nContinue?\n"
                )
              )
            Builtins.y2milestone("Proposing default values...")
            ProposeDefaultValues()
          end
        end
      elsif id == :ldap_expert_settings
        SambaLDAPExpertSettingsDialog()
      elsif id == :ldap_try_connect
        if SambaLDAPTryConnect()
          # translators: popup message
          Popup.Message(_("Connection successful."))
        end
      elsif id == :ldap_suse_defaults
        # translators: popup message
        if Popup.YesNo(
            _("All current LDAP-related values will be rewritten.\nContinue?\n")
          )
          ProposeDefaultValues()
        end
      end

      nil
    end

    def SambaLDAPSettingsEssentialWidgetValidate(key, event)
      event = deep_copy(event)
      passdb = Convert.to_boolean(
        UI.QueryWidget(Id(:ldap_passdb_backend_enable), :Value)
      )
      idmap = Convert.to_boolean(
        UI.QueryWidget(Id(:ldap_idmap_backend_enable), :Value)
      )
      return true if !passdb && !idmap

      return false if !SambaLDAPTryConnect()

      true
    end

    def SambaLDAPSettingsEssentialWidgetStore(key, event_descr)
      event_descr = deep_copy(event_descr)
      store_ldap_str("ldap admin dn")
      store_ldap_str("ldap suffix")

      passwd = Convert.to_string(UI.QueryWidget(Id(:passwd1), :Value))
      SambaBackendLDAP.SetAdminPassword(passwd)

      passdb = Convert.to_boolean(
        UI.QueryWidget(Id(:ldap_passdb_backend_enable), :Value)
      )
      idmap = Convert.to_boolean(
        UI.QueryWidget(Id(:ldap_idmap_backend_enable), :Value)
      )

      if passdb
        passdb_url = Convert.to_string(
          UI.QueryWidget(Id(:ldap_passdb_backend_url), :Value)
        )
        SambaBackend.AddPassdbBackend("ldapsam", passdb_url)
      else
        SambaBackend.RemovePassdbBackend("ldapsam")
      end

      if idmap
        idmap_url = Convert.to_string(
          UI.QueryWidget(Id(:ldap_idmap_backend_url), :Value)
        )
        SambaConfig.GlobalSetStr("idmap backend", Ops.add("ldap:", idmap_url))
      else
        SambaConfig.GlobalSetStr("idmap backend", nil)
      end

      nil
    end

    def CreateSambaLDAPSettingsEssentialWidget
      basedn = VBox(
        # translators: text entry label
        TextEntry(Id("ldap suffix"), _("&Search Base DN"))
      )
      auth = Frame(
        _("Authentication"),
        VBox(
          # translators: text entry label
          TextEntry(Id("ldap admin dn"), _("&Administration DN")),
          # BNC #446794
          HSquash(
            VBox(
              # TODO: if Mode::config() => no ask for pssword
              # translators: password enrty label
              Password(
                Id(:passwd1),
                Opt(:hstretch),
                _("Administration &Password")
              ),
              # translators: reenter password entry label
              Password(
                Id(:passwd2),
                Opt(:hstretch),
                _("Administration Password (A&gain)")
              )
            )
          ),
          ReplacePoint(Id("passwd_label"), Label("")),
          Empty(Opt(:vstretch))
        )
      )
      passdb =
        # translators: frame title (passdb == password database)
        Frame(
          _("Passdb Back-End"),
          VBox(
            # translators: check box label
            Left(
              CheckBox(
                Id(:ldap_passdb_backend_enable),
                Opt(:notify),
                _("Use LDAP Password &Back-End")
              )
            ),
            # translators: text entry label
            TextEntry(Id(:ldap_passdb_backend_url), _("LDAP Server &URL")),
            Empty(Opt(:vstretch))
          )
        )

      idmap =
        # translators: frame title (idmap = user id mapping)
        Frame(
          _("Idmap Back-End"),
          VBox(
            # translators: check box label
            Left(
              CheckBox(
                Id(:ldap_idmap_backend_enable),
                Opt(:notify),
                _("Use LDAP &Idmap Back-End")
              )
            ),
            # translators: text entry label
            TextEntry(Id(:ldap_idmap_backend_url), _("LDAP Server U&RL")),
            Empty(Opt(:vstretch))
          )
        )


      essential_widget = Top(
        HBox(
          HSpacing(1),
          VBox(
            VWeight(1, Empty()),
            VSquash(
              HBox(
                HWeight(1, VBox(passdb, idmap)),
                HSpacing(1),
                HWeight(1, auth)
              )
            ),
            VWeight(1, Empty()),
            basedn,
            VWeight(8, Empty()),
            Right(
              HBox(
                PushButton(Id(:ldap_try_connect), _("&Test Connection")),
                MenuButton(
                  Id(:ldap_advanced_settings),
                  _("Advanced &Settings..."),
                  [
                    Item(Id(:ldap_expert_settings), _("Expert LDAP Settings")),
                    Item(Id(:ldap_suse_defaults), _("Default Values"))
                  ]
                )
              )
            )
          ),
          HSpacing(1)
        )
      )

      {
        "widget"            => :custom,
        "custom_widget"     => essential_widget,
        "init"              => fun_ref(
          method(:SambaLDAPSettingsEssentialWidgetInit),
          "void (string)"
        ),
        "handle"            => fun_ref(
          method(:SambaLDAPSettingsEssentialWidgetHandle),
          "symbol (string, map)"
        ),
        "store"             => fun_ref(
          method(:SambaLDAPSettingsEssentialWidgetStore),
          "void (string, map)"
        ),
        "validate_type"     => :function,
        "validate_function" => fun_ref(
          method(:SambaLDAPSettingsEssentialWidgetValidate),
          "boolean (string, map)"
        ),
        "help"              => Ops.get_string(
          @HELPS,
          "samba_ldap_setting_auth_widget",
          ""
        )
      }
    end


    # Sambs LDAP Settings Suffixes Widget
    #////////////////////////////////////////////////////////////////////

    def SambaLDAPSettingsSuffixesWidgetInit(key)
      init_ldap_str("ldap user suffix")
      init_ldap_str("ldap group suffix")
      init_ldap_str("ldap machine suffix")
      init_ldap_str("ldap idmap suffix")

      nil
    end

    def SambaLDAPSettingsSuffixesWidgetStore(key, event_descr)
      event_descr = deep_copy(event_descr)
      store_ldap_str("ldap user suffix")
      store_ldap_str("ldap group suffix")
      store_ldap_str("ldap machine suffix")
      store_ldap_str("ldap idmap suffix")

      nil
    end

    def CreateSambaLDAPSettingsSuffixesWidget
      # translators: frame label
      suffixes_widget = Frame(
        _("Suffixes"),
        VBox(
          # translators: text entry label
          Left(TextEntry(Id("ldap user suffix"), _("&User Suffix"))),
          # translators: text entry label
          Left(TextEntry(Id("ldap group suffix"), _("&Group Suffix"))),
          # translators: text entry label
          Left(TextEntry(Id("ldap machine suffix"), _("&Machine Suffix"))),
          # translators: text entry label
          Left(TextEntry(Id("ldap idmap suffix"), _("&Idmap Suffix")))
        )
      )

      {
        "widget"        => :custom,
        "custom_widget" => suffixes_widget,
        "init"          => fun_ref(
          method(:SambaLDAPSettingsSuffixesWidgetInit),
          "void (string)"
        ),
        "store"         => fun_ref(
          method(:SambaLDAPSettingsSuffixesWidgetStore),
          "void (string, map)"
        ),
        "help"          => Ops.get_string(
          @HELPS,
          "samba_ldap_setting_suffixes_widget",
          ""
        )
      }
    end


    # Samba LDAP Settings Timeouts Widget
    #/////////////////////////////////////////////////////////////////////////

    def SambaLDAPSettingsTimeoutsWidgetInit(key)
      init_ldap_int("ldap timeout")
      init_ldap_int("ldap replication sleep")

      nil
    end

    def SambaLDAPSettingsTimeoutsWidgetStore(key, event_descr)
      event_descr = deep_copy(event_descr)
      store_ldap_int("ldap timeout")
      store_ldap_int("ldap replication sleep")

      nil
    end

    def CreateSambaLDAPSettingsTimeoutsWidget
      # translators: frame label
      timeouts_widget = Frame(
        _("Time-Outs"),
        VBox(
          # translators: integer field label
          Left(
            IntField(
              Id("ldap replication sleep"),
              _("&Replication Sleep"),
              0,
              999999,
              3
            )
          ),
          # translators: integer field label
          Left(IntField(Id("ldap timeout"), _("&Time-Out"), 0, 999999, 3))
        )
      )

      {
        "widget"        => :custom,
        "custom_widget" => timeouts_widget,
        "init"          => fun_ref(
          method(:SambaLDAPSettingsTimeoutsWidgetInit),
          "void (string)"
        ),
        "store"         => fun_ref(
          method(:SambaLDAPSettingsTimeoutsWidgetStore),
          "void (string, map)"
        ),
        "help"          => Ops.get_string(
          @HELPS,
          "samba_ldap_settings_timeouts_widget",
          ""
        )
      }
    end

    def SambaLDAPSettingsSecurityWidgetInit(key)
      init_ldap_combo("ldap ssl", @ldap_ssl_values)

      nil
    end

    def SambaLDAPSettingsSecurityWidgetStore(key, event_descr)
      event_descr = deep_copy(event_descr)
      store_ldap_str("ldap ssl")

      nil
    end

    def CreateSambaLDAPSettingsSecurityWidget
      # translators: frame label
      widget = Frame(
        _("Security"),
        VBox(
          # translators: combo box label
          Left(
            ComboBox(
              Id("ldap ssl"),
              _("&Use SSL or TLS"),
              Builtins.maplist(@ldap_ssl_values) do |l|
                Item(Id(Ops.get_string(l, 0, "")), Ops.get_string(l, 1, ""))
              end
            )
          )
        )
      )

      {
        "widget"        => :custom,
        "custom_widget" => widget,
        "init"          => fun_ref(
          method(:SambaLDAPSettingsSecurityWidgetInit),
          "void (string)"
        ),
        "store"         => fun_ref(
          method(:SambaLDAPSettingsSecurityWidgetStore),
          "void (string, map)"
        ),
        "help"          => Ops.get_string(
          @HELPS,
          "samba_ldap_settings_security_widget",
          ""
        )
      }
    end

    def SambaLDAPSettingsMiscWidgetInit(key)
      # init_ldap_str("ldap filter");
      init_ldap_combo("ldap delete dn", @ldap_yes_no_values)
      init_ldap_combo("ldap passwd sync", @ldap_yes_no_only_values)

      nil
    end

    def SambaLDAPSettingsMiscWidgetStore(key, event_descr)
      event_descr = deep_copy(event_descr)
      # store_ldap_str("ldap filter");
      store_ldap_str("ldap delete dn")
      store_ldap_str("ldap passwd sync")

      nil
    end

    def CreateSambaLDAPSettingsMiscWidget
      # translators: frame label
      misc_widget = Frame(
        _("Other Settings"),
        VBox(
          # No such option, bug 169194
          # translators: text entry label
          # `Left(`TextEntry(`id("ldap filter"), _("Search &Filter"))),

          # translators: combo box label
          Left(
            ComboBox(
              Id("ldap delete dn"),
              _("&Delete DN"),
              Builtins.maplist(@ldap_yes_no_values) do |l|
                Item(Id(Ops.get_string(l, 0, "")), Ops.get_string(l, 1, ""))
              end
            )
          ),
          # translators: combo box label
          Left(
            ComboBox(
              Id("ldap passwd sync"),
              _("&Synchronize Passwords"),
              Builtins.maplist(@ldap_yes_no_only_values) do |l|
                Item(Id(Ops.get_string(l, 0, "")), Ops.get_string(l, 1, ""))
              end
            )
          )
        )
      )

      {
        "widget"        => :custom,
        "custom_widget" => misc_widget,
        "init"          => fun_ref(
          method(:SambaLDAPSettingsMiscWidgetInit),
          "void (string)"
        ),
        "store"         => fun_ref(
          method(:SambaLDAPSettingsMiscWidgetStore),
          "void (string, map)"
        ),
        "help"          => Ops.get_string(
          @HELPS,
          "samba_ldap_settings_misc_widget",
          ""
        )
      }
    end
    def SambaLDAPExpertSettingsDialog
      widget_descr = {
        "SUFFIXES" => CreateSambaLDAPSettingsSuffixesWidget(),
        "TIMEOUTS" => CreateSambaLDAPSettingsTimeoutsWidget(),
        "SECURITY" => CreateSambaLDAPSettingsSecurityWidget(),
        "MISC"     => CreateSambaLDAPSettingsMiscWidget()
      }

      contents = VBox(
        HBox(
          HSpacing(1),
          HWeight(1, VBox("SECURITY", "SUFFIXES", Empty(Opt(:vstretch)))),
          HSpacing(1),
          HWeight(1, VBox("TIMEOUTS", "MISC", Empty(Opt(:vstretch)))),
          HSpacing(1)
        ),
        VStretch()
      )

      Wizard.CreateDialog
      ret = CWM.ShowAndRun(
        {
          "widget_names" => ["SUFFIXES", "TIMEOUTS", "SECURITY", "MISC"],
          "widget_descr" => widget_descr,
          "contents"     => contents,
          # translators: dialog caption
          "caption"      => _(
            "Expert LDAP Settings"
          ),
          "back_button"  => Label.CancelButton,
          "next_button"  => Label.OKButton,
          "abort_button" => nil
        }
      )
      UI.CloseDialog

      ret
    end
  end
end
