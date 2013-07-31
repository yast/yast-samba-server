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

# File:	modules/dialogs-items.ycp
# Package:	Configuration of samba-server
# Summary:	Widgets used by SAMBA server configuration
# Authors:	Jiri Srain <jsrain@suse.cz>
#		Stanislav Visnovsky <visnov@suse.cz>
#		Martin Lazar <mlazar@suse.cz>
#
# $Id$
module Yast
  module SambaServerDialogsItemsInclude
    def initialize_samba_server_dialogs_items(include_target)
      Yast.import "UI"

      textdomain "samba-server"

      Yast.import "Label"
      Yast.import "Popup"
      Yast.import "LogView"
      Yast.import "TablePopup"
      Yast.import "FileUtils"
      Yast.import "Report"

      Yast.import "SambaServer"
      Yast.import "SambaConfig"
      Yast.import "SambaBackend"

      Yast.include include_target, "samba-server/helps.rb"
      Yast.include include_target, "samba-server/complex.rb"

      Yast.include include_target, "samba-server/samba-options-local.rb"
      Yast.include include_target, "samba-server/samba-options-global.rb"

      #//////////////////////////////////
      @shareswidget = TablePopup.CreateTableDescr(
        {
          "add_delete_buttons" => true,
          "up_down_buttons"    => false,
          "unique_keys"        => true
        },
        {
          "init"          => fun_ref(method(:ShareInitFun), "void (string)"),
          "handle"        => fun_ref(
            method(:ShareHandleFun),
            "symbol (string, map)"
          ),
          "options"       => @local_option_widgets,
          "ids"           => fun_ref(method(:ShareEditContents), "list (map)"),
          "fallback"      => {
            "init"    => fun_ref(
              method(:ShareEditPopupInit),
              "void (any, string)"
            ),
            "store"   => fun_ref(
              method(:ShareEditPopupStore),
              "void (any, string)"
            ),
            "summary" => fun_ref(
              method(:ShareEditSummary),
              "string (any, string)"
            )
          },
          "option_delete" => fun_ref(
            method(:ShareEditEntryDelete),
            "boolean (any, string)"
          ),
          "add_items"     => Builtins.maplist(@local_option_widgets) do |key, values|
            key
          end,
          "help"          => Ops.get_string(@HELPS, "share_edit", "")
        }
      )

      @globalsettingswidget = TablePopup.CreateTableDescr(
        {
          "add_delete_buttons" => true,
          "up_down_buttons"    => false,
          "unique_keys"        => true
        },
        {
          "options"       => @global_option_widgets,
          "ids"           => fun_ref(
            method(:GlobalSettingsContents),
            "list (map)"
          ),
          "fallback"      => {
            "init"    => fun_ref(
              method(:GlobalSettingsPopupInit),
              "void (any, string)"
            ),
            "store"   => fun_ref(
              method(:GlobalSettingsPopupStore),
              "void (any, string)"
            ),
            "summary" => fun_ref(
              method(:GlobalSettingsSummary),
              "string (any, string)"
            )
          },
          "option_delete" => fun_ref(
            method(:GlobalSettingsEntryDelete),
            "boolean (any, string)"
          ),
          "add_items"     => Builtins.maplist(@global_option_widgets) do |key, values|
            key
          end,
          "help"          => Ops.get_string(@HELPS, "global_settings", "")
        }
      )

      @passdboptions =
        # MySQL will not be offered, unknown backend
        #    "mysql" : $[
        #        "table" : $[
        #	    // table entry description for MySQL-based SAM
        #           "label" : _("MySQL database"),
        #        ],
        #        "popup" : $[
        #         "widget" : `textentry,
        #        ],
        #    ],
        {
          "smbpasswd" => {
            "table" => {
              # table entry description for smbpasswd-based SAM
              "label" => _(
                "smbpasswd file"
              )
            },
            "popup" => { "widget" => :textentry }
          },
          "ldapsam"   => {
            "table" => {
              # table entry description for LDAP-based SAM
              "label" => _("LDAP")
            },
            "popup" => {
              "widget"            => :textentry,
              "validate_type"     => :function,
              "validate_function" => fun_ref(
                method(:ValidateLDAPURL),
                "boolean (any, string, map)"
              )
            }
          },
          "tdbsam"    => {
            "table" => {
              # table entry description for TDB-based SAM
              "label" => _(
                "TDB database"
              )
            },
            "popup" => { "widget" => :textentry }
          }
        }

      @passdbwidget = TablePopup.CreateTableDescr(
        {
          "add_delete_buttons" => true,
          "up_down_buttons"    => false,
          "unique_keys"        => false
        },
        {
          "init"              => fun_ref(method(:initPassdb), "void (string)"),
          "handle"            => fun_ref(
            method(:handlePassdb),
            "symbol (string, map)"
          ),
          "store"             => fun_ref(
            method(:storePassdb),
            "void (string, map)"
          ),
          "ids"               => fun_ref(
            method(:PassdbEditContents),
            "list (map)"
          ),
          "help"              => Ops.get_string(@HELPS, "passdb_edit", ""),
          "options"           => @passdboptions,
          "add_items"         => ["smbpasswd", "ldapsam", "tdbsam"],
          "add_unlisted"      => false,
          "id2key"            => fun_ref(
            method(:PassdbId2Key),
            "string (map, any)"
          ),
          "option_delete"     => fun_ref(
            method(:PassdbEntryDelete),
            "boolean (any, string)"
          ),
          "validate_type"     => :function,
          "validate_function" => fun_ref(
            method(:PassdbEditOptionValidate),
            "boolean (string, map)"
          ),
          # only one passdb backend is possible
          # "option_move" : PassdbOptionMove,
          "fallback"          => {
            "init"    => fun_ref(
              method(:PassdbEditOptionInit),
              "void (any, string)"
            ),
            "store"   => fun_ref(
              method(:PassdbEditOptionStore),
              "void (any, string)"
            ),
            "summary" => fun_ref(
              method(:PassdbEditOptionSummary),
              "string (any, string)"
            )
          }
        }
      )


      # Map of widgets for CWM
      @xx_widgets = {
        "share_edit"     => @shareswidget,
        "passdb_edit"    => @passdbwidget,
        "globalsettings" => @globalsettingswidget
      }


      # A share name do be editted in the Edit share dialog
      @shareToEdit = nil

      #************************************ passdb list table ***********************************

      @max_id = 0
      @passdb_backends = nil
      @passdb_order = []
    end

    def ValidateLDAPURL(opt_id, opt_key, event_descr)
      opt_id = deep_copy(opt_id)
      event_descr = deep_copy(event_descr)
      Yast.import "URL"

      url = Convert.to_string(UI.QueryWidget(Id(opt_key), :Value))

      if Builtins.regexpmatch(url, "^[ \t]+")
        # TRANSLATORS: popup error
        Report.Error(_("Optional value must not begin with a space character."))
        return false
      end

      quotes_used = false

      # ldapsam:"ldap://ldap1.example.com ldap://ldap2.example.com"
      if Builtins.regexpmatch(url, "^\".*\"[ \t]*$")
        quotes_used = true
        url = Builtins.regexpsub(url, "^\"(.*)\"[ \t]*$", "\\1")
      end

      urls = Builtins.splitstring(url, " \t")
      urls = Builtins.filter(urls) { |url2| url2 != "" }

      if Ops.greater_than(Builtins.size(urls), 1) && !quotes_used
        # TRANSLATORS: popup error
        Report.Error(
          _("Multiple optional values for one backend must be quoted.")
        )
        return false
      end

      ret = true
      Builtins.foreach(urls) do |url2|
        next if ret != true
        if !URL.Check(url2)
          Builtins.y2error("Invalid url '%1'", url2)
          # TRANSLATORS: popup error, %1 is replaced with some URL
          Popup.Error(
            Builtins.sformat(_("The entered URL '%1' is invalid"), url2)
          )
          ret = false
        end
        u = URL.Parse(url2)
        if Ops.get(u, "scheme") != "ldap" && Ops.get(u, "scheme") != "ldaps"
          Builtins.y2error("Invalid url '%1'", url2)
          # TRANSLATORS: popup error, %1 is replaced with some URL
          Popup.Error(
            Builtins.sformat(_("The entered URL '%1' is invalid"), url2)
          )
          ret = false
        end
      end

      ret
    end

    def SharePathWarning(p)
      text = nil

      if p == "/"
        text = @root_warning
      else
        text = Ops.get(@warnings, p) if Ops.get(@warnings, p) != nil
      end

      return Popup.ContinueCancel(text) if text != nil

      true
    end
    def ValidateSharePath(opt_id, opt_key, event_descr)
      opt_id = deep_copy(opt_id)
      event_descr = deep_copy(event_descr)
      p = Convert.to_string(UI.QueryWidget(Id(opt_key), :Value))

      return false if !SharePathWarning(p)
      return false if !FileUtils.CheckAndCreatePath(p)

      true
    end
    def ShareInitFun(key)
      TablePopup.TableInit(Ops.get_map(@xx_widgets, "share_edit", {}), key)

      nil
    end
    def ShareHandleFun(key, event_descr)
      event_descr = deep_copy(event_descr)
      TablePopup.TableHandle(
        Ops.get_map(@xx_widgets, "share_edit", {}),
        key,
        event_descr
      )
    end
    def ShareEditContents(descr)
      descr = deep_copy(descr)
      SambaConfig.ShareKeys(@shareToEdit)
    end
    def ShareEditEntryDelete(opt_id, opt_key)
      opt_id = deep_copy(opt_id)
      # message popup
      return false if !Popup.YesNo(_("Delete the selected entry?"))
      SambaConfig.ShareSetStr(@shareToEdit, opt_key, nil)
      true
    end
    def ShareEditPopupInit(opt_id, opt_key)
      opt_id = deep_copy(opt_id)
      if opt_id != nil
        # not adding a new option
        val = UI.QueryWidget(Id(opt_key), :Value)
        if Ops.is_boolean?(val)
          UI.ChangeWidget(
            Id(opt_key),
            :Value,
            SambaConfig.ShareGetTruth(@shareToEdit, opt_key, nil)
          )
        else
          UI.ChangeWidget(
            Id(opt_key),
            :Value,
            SambaConfig.ShareGetStr(@shareToEdit, opt_key, nil)
          )
        end
      end
      UI.SetFocus(Id(opt_key))

      nil
    end
    def ShareEditPopupStore(opt_id, opt_key)
      opt_id = deep_copy(opt_id)
      val = UI.QueryWidget(Id(opt_key), :Value)
      if Ops.is_boolean?(val)
        SambaConfig.ShareSetTruth(
          @shareToEdit,
          opt_key,
          Convert.to_boolean(val)
        )
      else
        SambaConfig.ShareSetStr(@shareToEdit, opt_key, Convert.to_string(val))
      end

      nil
    end
    def ShareEditSummary(opt_id, opt_key)
      opt_id = deep_copy(opt_id)
      SambaConfig.ShareGetStr(@shareToEdit, opt_key, "")
    end
    def GlobalSettingsContents(descr)
      descr = deep_copy(descr)
      SambaConfig.GlobalKeys
    end
    def GlobalSettingsEntryDelete(opt_id, opt_key)
      opt_id = deep_copy(opt_id)
      # message popup
      return false if !Popup.YesNo(_("Delete the selected entry?"))
      SambaConfig.GlobalSetStr(opt_key, nil)
      true
    end
    def GlobalSettingsPopupInit(opt_id, opt_key)
      opt_id = deep_copy(opt_id)
      if opt_id != nil
        val = UI.QueryWidget(Id(opt_key), :Value)
        if Ops.is_boolean?(val)
          UI.ChangeWidget(
            Id(opt_key),
            :Value,
            SambaConfig.GlobalGetTruth(opt_key, nil)
          )
        else
          UI.ChangeWidget(
            Id(opt_key),
            :Value,
            SambaConfig.GlobalGetStr(opt_key, nil)
          )
        end
      end
      UI.SetFocus(Id(opt_key))

      nil
    end
    def GlobalSettingsPopupStore(opt_id, opt_key)
      opt_id = deep_copy(opt_id)
      val = UI.QueryWidget(Id(opt_key), :Value)
      if Ops.is_boolean?(val)
        SambaConfig.GlobalSetTruth(opt_key, Convert.to_boolean(val))
      else
        SambaConfig.GlobalSetStr(opt_key, Convert.to_string(val))
      end

      nil
    end
    def GlobalSettingsSummary(opt_id, opt_key)
      opt_id = deep_copy(opt_id)
      SambaConfig.GlobalGetStr(opt_key, "")
    end

    def SomeBackendsAreInUse
      Ops.greater_than(Builtins.size(@passdb_backends), 0)
    end

    def RedrawPassdbEditButtons
      if UI.WidgetExists(Id(:_tp_add))
        UI.ChangeWidget(Id(:_tp_add), :Enabled, !SomeBackendsAreInUse())
      end

      nil
    end
    def PassdbEditContents(descr)
      descr = deep_copy(descr)
      if @passdb_backends != nil
        # we are already initialized
        return deep_copy(@passdb_order)
      else
        l = SambaBackend.GetPassdbBackends
        ids = []
        @max_id = -1
        @passdb_backends = Builtins.listmap(l) do |backend|
          @max_id = Ops.add(@max_id, 1)
          s = Builtins.sformat("%1", @max_id)
          ids = Builtins.add(ids, s)
          { s => backend }
        end
        @max_id = Ops.add(@max_id, 1)
        @passdb_order = deep_copy(ids)
        return deep_copy(ids)
      end
    end
    def PassdbEditOptionValidate(key, event_descr)
      event_descr = deep_copy(event_descr)
      if !SomeBackendsAreInUse()
        Report.Error(_("At least one backend must be specified."))

        return false
      end

      true
    end
    def PassdbEditOptionInit(opt_id, opt_key)
      opt_id = deep_copy(opt_id)
      if opt_id != nil
        # not adding a new option
        UI.ChangeWidget(
          Id(opt_key),
          :Value,
          SambaBackend.GetLocation(
            Ops.get(@passdb_backends, Convert.to_string(opt_id), "")
          )
        )
      end
      UI.SetFocus(Id(opt_key))

      RedrawPassdbEditButtons()

      nil
    end
    def PassdbEditOptionStore(opt_id, opt_key)
      opt_id = deep_copy(opt_id)
      details = Convert.to_string(UI.QueryWidget(Id(opt_key), :Value))
      # TODO: handle empty details

      if Builtins.size(details) != 0
        details = Ops.add(":", details)
      else
        details = ""
      end

      if opt_id != nil
        # update
        # take the SAM type from the old data and append the new details
        Ops.set(
          @passdb_backends,
          Convert.to_string(opt_id),
          Ops.add(
            SambaBackend.GetName(
              Ops.get(@passdb_backends, Convert.to_string(opt_id))
            ),
            details
          )
        )
      else
        # insert new
        id = Builtins.sformat("%1", @max_id)
        @max_id = Ops.add(@max_id, 1)
        @passdb_backends = Builtins.add(
          @passdb_backends,
          id,
          Ops.add(opt_key, details)
        )
        @passdb_order = Builtins.add(@passdb_order, id)
      end

      nil
    end
    def PassdbEditOptionSummary(opt_id, opt_key)
      opt_id = deep_copy(opt_id)
      option = Ops.get(@passdb_backends, Convert.to_string(opt_id), "")
      SambaBackend.GetLocation(option)
    end
    def PassdbId2Key(desc, id)
      desc = deep_copy(desc)
      id = deep_copy(id)
      s_id = Ops.get(@passdb_backends, Convert.to_string(id), "")
      SambaBackend.GetName(s_id)
    end
    def PassdbEntryDelete(opt_id, opt_key)
      opt_id = deep_copy(opt_id)
      #	if (size (passdb_backends) == 1)
      #	{
      #	    // error message if user tries to delete the last passdb backend
      #	    Report::Error (_("At least one back-end must be specified.
      #
      #The back-end cannot be deleted.
      #"));
      #	    return false;
      #	}

      # message popup
      return false if !Popup.YesNo(_("Delete the selected back-end?"))

      id = Convert.to_string(opt_id)
      @passdb_backends = Builtins.filter(@passdb_backends) { |k, v| k != id }
      @passdb_order = Builtins.filter(@passdb_order) { |k| k != id }

      RedrawPassdbEditButtons()

      true
    end
    def AddPassdbBackend
      UI.OpenDialog(
        VBox(
          # translators: frame text when adding a passdb backend
          Frame(
            _("Back-End Type"),
            RadioButtonGroup(
              Id(:types),
              VBox(
                # translators: passdb backend radio button
                Left(
                  RadioButton(
                    Id("smbpasswd"),
                    Opt(:notify),
                    _("smbpasswd File")
                  )
                ), # Unknown passdb backend
                #		    // translators: passdb backend radio button
                #		    `Left (`RadioButton ( `id("mysql"), `opt (`notify),_("MySQL Database") ) )
                # translators: passdb backend radio button
                Left(RadioButton(Id("ldapsam"), Opt(:notify), _("LDAP"))),
                # translators: passdb backend radio button
                Left(RadioButton(Id("tdbsam"), Opt(:notify), _("TDB Database")))
              )
            )
          ),
          # translators: textentry label to enter details for the selected passdb backend
          TextEntry(Id("details"), _("&Details")),
          HBox(
            PushButton(Id("add"), Opt(:default), Label.AddButton),
            PushButton(Id("cancel"), Label.CancelButton)
          )
        )
      )
      begin
        ret = UI.UserInput
        if Builtins.contains(["smbpasswd", "ldapsam", "tdbsam", "mysql"], ret)
          # prefill a hint, if details empty
          details = Convert.to_string(UI.QueryWidget(Id("details"), :Value))
          if Builtins.size(details) == 0
            if ret == "ldapsam"
              Yast.import "Ldap"
              # ask LDAP client for the value
              server = Ldap.server

              # ensure to take only the first one
              servers = Builtins.splitstring(server, " ")
              UI.ChangeWidget(
                Id("details"),
                :Value,
                Ops.add("ldap://", Ops.get(servers, 0, "localhost"))
              )
            end
          end

          next
        elsif ret == "add"
          # check: all types except smbpasswd must get detailed info
          type = Convert.to_string(UI.QueryWidget(Id(:types), :CurrentButton))
          details = Convert.to_string(UI.QueryWidget(Id("details"), :Value))
          if Builtins.size(details) != 0
            details = Ops.add(":", details)
          else
            details = ""
          end

          if type == "mysql" && Builtins.size(details) == 0
            # translators: error message, if the MySQL backend
            # is selected, but no details are entered
            Popup.Error(
              _(
                "An identifier must be provided\n" +
                  "in details \n" +
                  "for the MySQL passdb back-end.\n" +
                  "\n" +
                  "Consult the Samba HOWTO collection for\n" +
                  "further information.\n"
              )
            )
            next
          # validate LDAP
          elsif type == "ldapsam" && Ops.greater_than(Builtins.size(details), 0)
            # fill in empty params to keep interpreter happy
            next if !ValidateLDAPURL(nil, "details", nil)
          end

          # add the value
          id = Builtins.sformat("%1", @max_id)
          @max_id = Ops.add(@max_id, 1)
          @passdb_backends = Builtins.add(
            @passdb_backends,
            id,
            Ops.add(type, details)
          )
          @passdb_order = Builtins.add(@passdb_order, id)
        end
        break
      end while true

      UI.CloseDialog

      nil
    end
    def PassdbOptionMove(opt_id, opt_key, direction)
      opt_id = deep_copy(opt_id)
      id = Convert.to_string(opt_id)

      @passdb_order = Builtins.sort(@passdb_order) do |left, right|
        res = direction == :down ?
          left == id ? false : true :
          right == id ? false : true
        res
      end
      initPassdb(opt_key)
      deep_copy(opt_id)
    end
    def initPassdb(key)
      TablePopup.TableInit(Ops.get_map(@xx_widgets, "passdb_edit", {}), key)
      RedrawPassdbEditButtons()

      nil
    end
    def handlePassdb(key, event_descr)
      event_descr = deep_copy(event_descr)
      if Ops.get(event_descr, "ID") == :_tp_add
        AddPassdbBackend()
        TablePopup.TableInit(Ops.get_map(@xx_widgets, "passdb_edit", {}), key)
        RedrawPassdbEditButtons()
        # continue
        return nil
      end

      if Ops.get(event_descr, "ID") == :back
        @passdb_backends = nil
        return nil
      end

      ret = TablePopup.TableHandle(
        Ops.get_map(@xx_widgets, "passdb_edit", {}),
        key,
        event_descr
      )
      RedrawPassdbEditButtons()
      ret
    end
    def storePassdb(key, event)
      event = deep_copy(event)
      res = Builtins.maplist(@passdb_order) do |id|
        Ops.get(@passdb_backends, id, "")
      end
      SambaBackend.SetPassdbBackends(res)
      @passdb_backends = nil # require a new initialization

      nil
    end
  end
end
