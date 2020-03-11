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

# File:	include/samba-server/dialogs.ycp
# Package:	Configuration of samba-server
# Summary:	Dialogs definitions
# Authors:	Stanislav Visnovsky <stanislav.visnovsky@suse.cz>
#		Lukas Ocilka <locilka@suse.cz>
#
# $Id$

require "cwm/service_widget"

require "shellwords"

module Yast
  module SambaServerDialogsInclude

    def initialize_samba_server_dialogs(include_target)
      Yast.import "UI"

      textdomain "samba-server"

      Yast.import "String"
      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "Mode"
      Yast.import "Popup"
      Yast.import "ProductFeatures"
      Yast.import "FileUtils"

      Yast.import "SambaRole"
      Yast.import "SambaServer"
      Yast.import "SambaConfig"
      Yast.import "SambaService"
      Yast.import "SambaNetJoin"
      Yast.import "SambaTrustDom"
      Yast.import "SambaAccounts"
      Yast.import "SambaNmbLookup"
      Yast.import "Samba"
      Yast.import "SambaAD"

      Yast.import "CWM"
      Yast.import "CWMTab"
      Yast.import "CWMServiceStart"
      Yast.import "CWMFirewallInterfaces"
      Yast.import "OSRelease"

      Yast.include include_target, "samba-server/helps.rb"
      Yast.include include_target, "samba-server/dialogs-items.rb"
      Yast.include include_target, "samba-server/ldap-widget.rb"
      Yast.include include_target, "samba-client/routines.rb"
      Yast.include include_target, "samba-server/complex.rb"

      @return_tab = "startup"

      @pdc = _("&Primary Domain Controller (PDC)")
      @bdc = _("B&ackup Domain Controller (BDC)")
      @standalone = _("Not a Domain &Controller")

      #************************ initial wizard end *************************

      @initial_role = nil

      # User shares feature, bugzilla #143908
      @allow_share = true
      @max_shares = 0
      @shares_group = ""
      # Guest Access check-box, BNC #579993
      @guest_access = false

      @autoyast_warning_done = false

      @snapper_available        = nil
      @btrfs_available          = nil
    end

    # Widget to define status and start mode of the services
    #
    # There are two involved services, `smb` and `nmb`. See
    # {Yast::SambaServerComplexInclude#services}
    #
    # @return [::CWM::ServiceWidget]
    def service_widget
      return @service_widget if @service_widget
      @service_widget = ::CWM::ServiceWidget.new(services)
      @service_widget.default_action = :restart if need_to_restart? && !connected_users?
      @service_widget
    end

    # routines

    # check if snapper support is available (initial check)
    def snapper_available?
      if @snapper_available.nil?
        @snapper_available      =
          Package.Installed("snapper") &&
          # check for the presence of Samba's Snapper VFS module
          0 == SCR.Execute(path(".target.bash"), "/usr/sbin/smbd --build-options | /usr/bin/grep vfs_snapper_init")
      end
      @snapper_available
    end

    # check if Btrfs support is available (initial check)
    def btrfs_available?
      if @btrfs_available.nil?
        @btrfs_available      =
          # check for the presence of Samba's Btrfs VFS module
          0 == SCR.Execute(path(".target.bash"), "/usr/sbin/smbd --build-options | /usr/bin/grep vfs_btrfs_init")
      end
      @btrfs_available
    end

    # check if given path points to btrfs subvolume
    def subvolume?(path)
      return false unless path
      stat      = SCR.Read(path(".target.stat"), path)

      if stat["inode"] == 256
        return true
      else
        return false
      end
    end

    # check if given path has a corresponding snapper configuration
    def snapper_cfg?(path)
      return false unless path

      pattern = "SUBVOLUME=\"#{path}\""
      if 0 == SCR.Execute(path(".target.bash"), "/usr/bin/grep #{pattern.shellescape} /etc/snapper/configs/*")
        return true
      else
        return false
      end
    end

    def sharesItems(filt)
      shares = SambaConfig.GetShares
      if filt
        system = ["homes", "printers", "print$", "netlogon", "profiles"]
        shares = Builtins.filter(shares) { |s| !Builtins.contains(system, s) }
      end
      index = 0
      Builtins.maplist(shares) do |name|
        index = Ops.add(index, 1)
        pth = SambaConfig.ShareGetStr(name, "path", "")
        enabled = SambaConfig.ShareEnabled(name) ? _("Enabled") : _("Disabled")
        comment = SambaConfig.ShareGetStr(name, "comment", "")
        ro = SambaConfig.ShareGetTruth(name, "read only", true)
        ga = SambaConfig.ShareGetTruth(name, "guest ok", false)
        Item(
          Id(index),
          enabled,
          ro ? _("Yes") : _("No"),
          name,
          pth,
          ga ? _("Yes") : _("No"),
          comment
        )
      end
    end

    def confirmAbort
      Builtins.y2warning("confirm abort")
      return true if !SambaServer.GetModified

      Popup.ReallyAbort(true)
    end


    def Installation_Step1
      caption = _("Samba Installation") + ": " + _("Step 1 of 1")

      # feature dropped
      # list <string> workgroups = SambaNmbLookup::GetAvailableNeighbours(nil);

      # always add the currently configured workgroup
      workgroup = SambaConfig.GlobalGetStr("workgroup", "")
      #    if (size(workgroup) > 0 && !contains(workgroups, workgroup)) {
      #	workgroups = add(workgroups, workgroup);
      #    }

      contents = VBox(
        VSquash(
          Left(
            # `ComboBox ( `id( "workgroups" ), `opt( `editable ), _("&Workgroup or Domain Name"), workgroups )

            # TRANSLATORS: text entry
            InputField(
              Id("workgroups"),
              Opt(:hstretch),
              _("&Workgroup or Domain Name"),
              workgroup
            )
          )
        ),
        VStretch()
      )

      Wizard.SetContents(
        caption,
        contents,
        Ops.get_string(@HELPS, "inst_step1", ""),
        false,
        true
      )

      Wizard.DisableBackButton

      if Ops.greater_than(Builtins.size(workgroup), 0)
        UI.ChangeWidget(Id("workgroups"), :Value, workgroup)
      end

      ret = nil
      while true
        ret = UI.UserInput
        if ret == :next || ret == :cancel || ret == :abort
          break
        else
          Builtins.y2error("unexpected retcode: %1", ret)
          next
        end
      end

      if ret == :next
        sel = Convert.to_string(UI.QueryWidget(Id("workgroups"), :Value))
        Builtins.y2milestone("Setting workgroup '%1'", sel)
        SambaConfig.GlobalSetStr("workgroup", sel)
      end

      Wizard.RestoreBackButton

      deep_copy(ret)
    end

    def getRole
      role = SambaRole.GetRole
      return "STANDALONE" if role == "MEMBER"
      role
    end

    def BaseSettingsWidgetInit(key)
      UI.ChangeWidget(
        Id("workgroup_domainname"),
        :Value,
        SambaConfig.GlobalGetStr("workgroup", "")
      )

      # initial for this dialog
      # see also BNC #553349
      @initial_role = getRole
      UI.ChangeWidget(Id("domain_controller"), :Value, @initial_role)
      Builtins.y2milestone("Initial role: %1", @initial_role)

      nil
    end

    def WinsSettingsWidgetInit(key)
      wins = SambaConfig.GlobalGetTruth("wins support", false)

      UI.ChangeWidget(Id("wins_server_support"), :Value, wins)
      UI.ChangeWidget(Id("remote_wins_server"), :Value, !wins)
      UI.ChangeWidget(Id("wins_server_name"), :Enabled, !wins)
      UI.ChangeWidget(
        Id("wins_server_name"),
        :Value,
        SambaConfig.GlobalGetStr("wins server", "")
      )

      nil
    end

    def WinsViaDHCPWidgetInit(key)
      UI.ChangeWidget(Id(:dhcp), :Value, Samba.GetDHCP)

      nil
    end

    def WinsHostResolutionWidgetInit(key)
      UI.ChangeWidget(Id(:wins_dns), :Value, Samba.GetHostsResolution)

      nil
    end

    def GlobalConfigStringWidgetInit(key)
      UI.ChangeWidget(Id(key), :Value, SambaConfig.GlobalGetStr(key, ""))

      nil
    end

    def BaseSettingsWidgetStore(key, event_descr)
      event_descr = deep_copy(event_descr)
      sel = Convert.to_string(
        UI.QueryWidget(Id("workgroup_domainname"), :Value)
      )
      Builtins.y2milestone("Setting workgroup '%1'", sel)
      SambaConfig.GlobalSetStr("workgroup", sel)

      role = Convert.to_string(UI.QueryWidget(Id("domain_controller"), :Value))
      role = "MEMBER" if role == "STANDALONE" && SambaNmbLookup.IsDomain(sel)

      # Do not set the role if it is unchanged. It would rewrite some expert settings
      # that might have been set manually (Expert Settings), bugzilla #255824
      if Builtins.toupper(role) != Builtins.toupper(@initial_role)
        Builtins.y2milestone(
          "Setting role '%1' (was '%2')",
          role,
          SambaRole.GetRole
        )
        SambaRole.SetRole(role)
      else
        Builtins.y2milestone("Role type not changed (%1)", role)
      end

      nil
    end

    def WinsSettingsWidgetStore(key, event_descr)
      event_descr = deep_copy(event_descr)
      if Convert.to_boolean(UI.QueryWidget(Id("wins_server_support"), :Value))
        Builtins.y2milestone("Enabling wins support")
        SambaConfig.GlobalSetTruth("wins support", true)
        SambaConfig.GlobalSetStr("wins server", nil)
      else
        SambaConfig.GlobalSetTruth("wins support", false)
        SambaConfig.GlobalSetStr(
          "wins server",
          Convert.to_string(UI.QueryWidget(Id("wins_server_name"), :Value))
        )
        Builtins.y2milestone(
          "Disabling wins support, using server '%1'",
          SambaConfig.GlobalGetStr("wins server", "<none>")
        )
      end

      nil
    end

    def WinsViaDHCPWidgetStore(key, event_descr)
      event_descr = deep_copy(event_descr)
      new_value = Convert.to_boolean(UI.QueryWidget(Id(:dhcp), :Value))
      if new_value != nil
        Builtins.y2milestone(
          "Setting WINS via DHCP to '%1' returned '%2'",
          new_value,
          Samba.SetDHCP(new_value)
        )
      end

      nil
    end

    def WinsHostResolutionWidgetStore(key, event_descr)
      event_descr = deep_copy(event_descr)
      new_value = Convert.to_boolean(UI.QueryWidget(Id(:wins_dns), :Value))
      if new_value != nil
        Builtins.y2milestone(
          "Setting WINS Host Resolution '%1' returned '%2'",
          new_value,
          Samba.SetHostsResolution(new_value)
        )
      end

      nil
    end

    def GlobalConfigStringWidgetStore(key, event_descr)
      event_descr = deep_copy(event_descr)
      value = Convert.to_string(UI.QueryWidget(Id(key), :Value))

      changed = SambaConfig.GlobalSetStr(key, value == "" ? nil : value)

      # warn about the netbios name change
      if key == "netbios name" && changed && !Mode.config
        Popup.Warning(Ops.get(@warnings, "netbios", ""))
      end

      nil
    end

    def WinsSettingsWidgetHandle(key, event_descr)
      event_descr = deep_copy(event_descr)
      event = Ops.get(event_descr, "ID")
      if event == "wins_server_support" || event == "remote_wins_server"
        UI.ChangeWidget(
          Id("wins_server_name"),
          :Enabled,
          event == "remote_wins_server"
        )
      end
      nil
    end

    def AdvancedSettingsWidgetHandle(key, event)
      event = deep_copy(event)
      if Ops.is_symbol?(Ops.get(event, "ID")) &&
          Builtins.contains(
            [:passdb, :global_settings],
            Ops.get_symbol(event, "ID", :cancel)
          )
        @return_tab = "identity"
        return Ops.get_symbol(event, "ID", :next)
      end
      nil
    end

    def InitUserShareWidgets
      @max_shares = Samba.GetMaxShares

      if @max_shares == 0
        @max_shares = 100
        @allow_share = false
      else
        @allow_share = true
      end

      @guest_access = @allow_share && Samba.GetGuessAccess

      @shares_group = Samba.shares_group

      UI.ChangeWidget(Id(:group), :Value, @shares_group)
      UI.ChangeWidget(Id(:max_shares), :Value, @max_shares)
      UI.ChangeWidget(Id(:share_ch), :Value, @allow_share)
      UI.ChangeWidget(Id(:guest_ch), :Value, @guest_access)

      nil
    end

    def AdjustUserShareWidgets
      Builtins.foreach([:group, :max_shares, :guest_ch]) do |t|
        UI.ChangeWidget(
          Id(t),
          :Enabled,
          Convert.to_boolean(UI.QueryWidget(Id(:share_ch), :Value))
        )
      end

      nil
    end

    def StoreUserShareWidgets(key, event_descr)
      event_descr = deep_copy(event_descr)
      new_share = Convert.to_boolean(UI.QueryWidget(Id(:share_ch), :Value))
      if new_share && !@allow_share && SharesExist(Samba.shares_dir)
        Samba.remove_shares = AskForSharesRemoval()
      end
      max = Convert.to_integer(UI.QueryWidget(Id(:max_shares), :Value))
      if !new_share
        max = 0
        # Samba::stop_services = AskToStopServices();
        Samba.stop_services = false
      end
      Samba.SetShares(
        max,
        Convert.to_string(UI.QueryWidget(Id(:group), :Value))
      )
      Samba.SetGuessAccess(
        new_share && Convert.to_boolean(UI.QueryWidget(Id(:guest_ch), :Value))
      )

      SambaServer.SetModified

      nil
    end

    def SharesWidgetInit(key)
      items = sharesItems(false)

      UI.ChangeWidget(Id(:table), :Items, items)
      UI.ChangeWidget(
        Id(:edit),
        :Enabled,
        Ops.greater_than(Builtins.size(items), 0)
      )
      UI.ChangeWidget(
        Id(:delete),
        :Enabled,
        Ops.greater_than(Builtins.size(items), 0)
      )
      UI.ChangeWidget(
        Id(:toggle),
        :Enabled,
        Ops.greater_than(Builtins.size(items), 0)
      )
      UI.ChangeWidget(
        Id(:guest),
        :Enabled,
        Ops.greater_than(Builtins.size(items), 0)
      )

      InitUserShareWidgets()
      AdjustUserShareWidgets()

      nil
    end

    # Bugzilla #263302
    def RenameShare(share)
      if !SambaConfig.ShareExists(share)
        Builtins.y2error("Share %1 doesn't exist", share)
        return false
      end

      content = VBox(
        # TRANSLATORS: dialog caption
        Heading(_("Rename Share")),
        HSquash(
          MinWidth(
            35,
            VBox(
              # TRANSLATORS: text entry
              InputField(
                Id("share_name"),
                Opt(:hstretch),
                _("New Share &Name"),
                share
              )
            )
          )
        ),
        VSpacing(1),
        ButtonBox(
          PushButton(Id(:ok), Opt(:okButton), Label.OKButton),
          PushButton(Id(:cancel), Opt(:cancelButton), Label.CancelButton)
        )
      )

      UI.OpenDialog(content)
      UI.SetFocus(Id("share_name"))

      fc_ret = false

      ret = nil
      while true
        ret = UI.UserInput

        if ret == :ok
          new_share_name = Convert.to_string(
            UI.QueryWidget(Id("share_name"), :Value)
          )

          if new_share_name == ""
            # TRANSLATORS: popup error message
            Report.Error(_("Enter a new share name."))
            next
          elsif share == new_share_name
            Builtins.y2milestone("Old and new share names are the same")
            break
          elsif SambaConfig.ShareExists(new_share_name)
            # TRANSLATORS: popup error message, %1 is a variable share name
            Report.Error(
              Builtins.sformat(
                _("Share '%1' already exists.\nChoose another share name.\n"),
                new_share_name
              )
            )
            next
          end

          # Renaming share
          old_share_settings = SambaConfig.ShareGetMap(share)
          old_share_enabled = SambaConfig.ShareEnabled(share)

          Builtins.y2milestone(
            "Creating new share '%1' %2 -> %3",
            new_share_name,
            old_share_settings,
            SambaConfig.ShareSetMap(new_share_name, old_share_settings)
          )
          Builtins.y2milestone(
            "Removing share '%1' -> %2",
            share,
            SambaConfig.ShareRemove(share)
          )

          # enable or disable new share according the old one
          if SambaConfig.ShareEnabled(new_share_name) != old_share_enabled
            SambaConfig.ShareAdjust(
              new_share_name,
              !SambaConfig.ShareEnabled(new_share_name)
            )
          end

          fc_ret = true
          break 
          # cancel
        else
          break
        end
      end

      UI.CloseDialog

      fc_ret
    end

    def SharesWidgetHandle(key, event_descr)
      event_descr = deep_copy(event_descr)
      return nil if !Ops.is_symbol?(Ops.get(event_descr, "ID"))
      ret = Ops.get_symbol(event_descr, "ID")
      @return_tab = "shares"

      if ret == :share_ch
        AdjustUserShareWidgets()
        return nil
      end
      return ret if ret == :add
      if ret == :filter_all || ret == :filter_non_system
        items = sharesItems(ret == :filter_non_system)
        UI.ChangeWidget(Id(:table), :Items, items)
        return nil
      end

      id = Convert.to_integer(UI.QueryWidget(Id(:table), :CurrentItem))
      return nil if id == nil

      share = Ops.get_string(
        Builtins.argsof(
          Convert.to_term(UI.QueryWidget(Id(:table), term(:Item, id)))
        ),
        3
      )
      return nil if share == nil

      if ret == :edit || ret == :table
        @shareToEdit = share
        return :edit
      end
      if ret == :toggle
        SambaConfig.ShareAdjust(share, !SambaConfig.ShareEnabled(share))
        UI.ChangeWidget(Id(:table), :Items, sharesItems(false))
        UI.ChangeWidget(Id(:table), :CurrentItem, id)
        return nil
      end
      if ret == :guest
        SambaConfig.ShareSetTruth(
          share,
          "guest ok",
          !SambaConfig.ShareGetTruth(share, "guest ok", false)
        )
        UI.ChangeWidget(Id(:table), :Items, sharesItems(false))
        UI.ChangeWidget(Id(:table), :CurrentItem, id)
        return nil
      end
      if ret == :delete
        # confirmation dialog before deleting a share
        if Popup.YesNo(
            Builtins.sformat(
              _(
                "If you delete share %1,\n" +
                  "all its settings will be lost.\n" +
                  "Really delete it?"
              ),
              share
            )
          )
          Builtins.y2milestone(
            "Removing share '%1' -> %2",
            share,
            SambaConfig.ShareRemove(share)
          )
          UI.ChangeWidget(Id(:table), :Items, sharesItems(false))
        end
      end
      if ret == :rename
        if RenameShare(share)
          UI.ChangeWidget(Id(:table), :Items, sharesItems(false))
        end
        return nil
      end

      nil
    end


    def AddTrustedDomain
      #rwalter I couldn't make this one show up. Please make sure my deletions didn't make it too confusing.
      contents = VBox(
        InputField(Id(:domain), Opt(:hstretch), _("Trusted &Domain")),
        Password(Id(:password), _("&Password")),
        VSpacing(1),
        HBox(
          PushButton(Id(:ok), Opt(:default), Label.OKButton),
          PushButton(Id(:cancel), Label.CancelButton)
        )
      )

      UI.OpenDialog(contents)
      UI.SetFocus(Id(:domain))

      ret = nil
      begin
        ret = Convert.to_symbol(UI.UserInput)

        if ret == :ok
          domain = Convert.to_string(UI.QueryWidget(:domain, :Value))
          passwd = Convert.to_string(UI.QueryWidget(:password, :Value))

          if Builtins.size(domain) == 0
            Yast.import "Report"
            Report.Error(_("Domain name cannot be empty."))
            ret = nil
          end
          success = SambaTrustDom.Establish(domain, passwd)
          if success != true
            Yast.import "Report"
            Report.Error(_("Cannot establish trusted domain relationship."))
            ret = nil
          end
        end
      end while ret == nil


      UI.CloseDialog

      nil
    end

    def TrustedDomainsWidgetInit(key)
      if Mode.config && !@autoyast_warning_done
        # issue a warning, if not already done so
        Popup.Warning(
          _(
            "The password for trusted domains\n" +
              "is stored in the autoinstallation control file. The password\n" +
              "is stored as plain text. This can be considered\n" +
              "a security threat."
          )
        )
        @autoyast_warning_done = true
      end

      domains = []

      # SambaTrustDom::List() might return 'nil'
      samba_trust_domain_list = SambaTrustDom.List
      if samba_trust_domain_list != nil || samba_trust_domain_list != []
        Builtins.foreach(samba_trust_domain_list) do |key2|
          domains = Builtins.add(domains, Item(Id(key2), key2))
        end
      end

      UI.ReplaceWidget(
        Id(:domains_tr),
        SelectionBox(Id("trusted_domains"), _("&Trusted Domains"), domains)
      )

      # disable delete button if needed
      UI.ChangeWidget(Id(:delete_domain), :Enabled, Builtins.size(domains) != 0)

      nil
    end

    def TrustedDomainsWidgetHandle(key, event_descr)
      event_descr = deep_copy(event_descr)
      if Ops.get(event_descr, "ID") == :add_domain
        AddTrustedDomain()
      elsif Ops.get(event_descr, "ID") == :delete_domain
        to_delete = Convert.to_string(
          UI.QueryWidget(Id("trusted_domains"), :CurrentItem)
        )

        # confirmation
        if Popup.ContinueCancel(
            Builtins.sformat(
              _("Really abandon trust relationship\nto trusted domain %1?"),
              to_delete
            )
          )
          SambaTrustDom.Revoke(to_delete)
        end
      end

      # reinitialize contents
      TrustedDomainsWidgetInit(key)

      nil
    end

    # EditShareDialog dialog
    # @return dialog result
    def EditShareDialog
      contents = HBox(HSpacing(1), VBox(VSpacing(1), "share_edit"), HSpacing(1))

      # dialog caption
      caption = Builtins.sformat(_("Share %1"), @shareToEdit)


      CWM.ShowAndRun(
        {
          "widget_names"       => ["share_edit"],
          "widget_descr"       => @xx_widgets,
          "contents"           => contents,
          "caption"            => caption,
          "back_button"        => Label.BackButton,
          "next_button"        => Label.OKButton,
          "abort_button"        => nil
        }
      )
    end

    def GlobalSettingsDialog
      contents = HBox(
        HSpacing(1),
        VBox(VSpacing(1), "globalsettings"),
        HSpacing(1)
      )

      # dialog caption
      caption = _("Expert Global Settings Configuration")

      res = CWM.ShowAndRun(
        {
          "widget_names"       => ["globalsettings"],
          "widget_descr"       => @xx_widgets,
          "contents"           => contents,
          "caption"            => caption,
          "back_button"        => Label.BackButton,
          "next_button"        => Label.OKButton,
          "fallback_functions" => {
            :abort => fun_ref(method(:confirmAbort), "boolean ()")
          }
        }
      )

      #    if (res == `next) {
      # update the rest of the settings using the entered ones
      #	SambaServer::role = SambaServer::DetermineRole();
      #    }

      res
    end

    def AddShareDialog
      default_path      = "/home"

      contents = HVSquash(HBox(
        HSpacing(1),
        VBox(Opt(:hstretch),
          VSpacing(1),
          # frame label
          Frame(_("Identification"), VBox(
            # text entry label
            InputField(Id(:name), Opt(:hstretch), _("Share &Name")),
            # text entry label
            InputField(Id(:comment), Opt(:hstretch), _("Share &Description"))
          )),
          VSpacing(1),
          # frame label
          Frame(_("Share Type"), HBox(
            HSpacing(1),
            VBox(Opt(:hstretch),
              RadioButtonGroup(VBox(
                # radio button label
                Left(RadioButton(Id(:printer), Opt(:notify), _("&Printer"))),
                # radio button label
                Left(RadioButton(Id(:directory), Opt(:notify), _("&Directory"), true))
              )),
              HBox(
                # translators: text entry label
                InputField(Id(:path), Opt(:notify), _("Share &Path"), default_path),
                VBox(
                  Label(""),
                  PushButton(Id(:browse), Label.BrowseButton)
                )
              ),
              # translators: checkbox label, setting for share
              Left(CheckBox(Id(:read_only), _("&Read-Only"), false)),
              # checkbox label
              Left(CheckBox(Id(:inherit_acls), _("&Inherit ACLs"), true)),
              # checkbox label
              Left(CheckBox(Id(:snapper_support), _("Expose Snapshots"), false)),
              # checkbox label
              Left(CheckBox(Id(:btrfs_support), _("Utilize Btrfs Features"), false))
            ),
            HSpacing(1)
          ))
        )
      ))

      Wizard.SetContentsButtons(
        # translators: dialog caption
        _("New Share"),
        contents,
        @HELPS["add_share"] || "",
        Label.BackButton,
        Label.OKButton
      )
      Wizard.HideAbortButton

      UI.SetFocus(Id(:name))
      UI.ChangeWidget(Id(:snapper_support), :Enabled, snapper_available? && subvolume?(default_path) && snapper_cfg?(default_path))
      UI.ChangeWidget(Id(:btrfs_support), :Enabled, btrfs_available? && subvolume?(default_path))

      ret = nil
      begin
        # enable/disable path
        on = UI.QueryWidget(Id(:directory), :Value)
        UI.ChangeWidget(Id(:path), :Enabled, on)
        UI.ChangeWidget(Id(:browse), :Enabled, on)
        UI.ChangeWidget(Id(:read_only), :Enabled, on)
        UI.ChangeWidget(Id(:inherit_acls), :Enabled, on)

        ret = UI.UserInput

        if ret == :cancel
          break if confirmAbort
          ret = nil
          next
        end

        if ret == :printer || ret == :directory
          ret = nil
          next
        end

        pathvalue = UI.QueryWidget(Id(:path), :Value)

        if ret == :path
          if snapper_available?
            UI.ChangeWidget(Id(:snapper_support), :Enabled, subvolume?(pathvalue) && snapper_cfg?(pathvalue))
          end
          if btrfs_available?
            UI.ChangeWidget(Id(:btrfs_support), :Enabled, subvolume?(pathvalue))
          end
          ret = nil
        elsif ret == :browse
          # translators: file selection dialog title
          dir = UI.AskForExistingDirectory(pathvalue, _("Path for a Share"))
          if dir
            UI.ChangeWidget(Id(:path), :Value, dir)
            if snapper_available?
              subvolume_cfg = subvolume?(dir) && snapper_cfg?(dir)
              UI.ChangeWidget(Id(:snapper_support), :Enabled, subvolume_cfg)
              UI.ChangeWidget(Id(:snapper_support), :Value, false) unless subvolume_cfg
            end
            if btrfs_available?
              subvolume = subvolume?(dir)
              UI.ChangeWidget(Id(:btrfs_support), :Enabled, subvolume)
              UI.ChangeWidget(Id(:btrfs_support), :Value, false) unless subvolume
            end
          end
          ret = nil
        elsif ret == :next
          # OK was pressed

          name          = UI.QueryWidget(Id(:name), :Value)
          comment       = UI.QueryWidget(Id(:comment), :Value)
          printable     = UI.QueryWidget(Id(:printer), :Value)

          if name.empty?
            # translators: error message
            Popup.Error(_("Share name cannot be empty."))
            ret = nil
            next
          elsif pathvalue.empty? && !printable
            # translators: error message
            Popup.Error(_("Share path cannot be empty."))
            ret = nil
            next
          elsif !printable && !SharePathWarning(pathvalue)
            ret = nil
            next
          elsif !printable && !Mode.config &&
              !FileUtils.CheckAndCreatePath(pathvalue)
            ret = nil
            next
          end

          res = { "comment" => comment }

          if printable
            res["printable"]    = "Yes"
            res["path"]         = "/var/tmp"
          else
            read_only           = UI.QueryWidget(Id(:read_only), :Value)
            inherit_acls        = UI.QueryWidget(Id(:inherit_acls), :Value)

            res["read only"]    = read_only ? "Yes" : "No"
            res["inherit acls"] = inherit_acls ? "Yes" : "No"
            res["path"]         = pathvalue
            res["vfs objects"]  = ""
            if snapper_available? && UI.QueryWidget(Id(:snapper_support), :Value)
              res["vfs objects"] << "snapper "
            end
            if btrfs_available? && UI.QueryWidget(Id(:btrfs_support), :Value)
              res["vfs objects"] << "btrfs "
            end
          end

          if SambaConfig.ShareExists(name)
            # translators: popup error message for "add share", %1 is share name
            Popup.Error(Builtins.sformat(_("Share %1 already exists."), name))
            ret = nil
          end
          SambaConfig.ShareSetMap(name, res)
        end
      end while ret == nil
      ret
    end



    def Installation_Conf_Tab
      shares_widget = HBox(
        HWeight(1, Empty()),
        HWeight(
          100,
          VBox(
            HBox(
              Left(Label(_("Available Shares"))),
              HStretch(),
              Right(
                MenuButton(
                  _("&Filter"),
                  [
                    Item(Id(:filter_all), _("Show &All Shares")),
                    Item(
                      Id(:filter_non_system),
                      _("Do Not Show &System Shares")
                    )
                  ]
                )
              )
            ),
            # translators: table header texts
            Table(
              Id(:table),
              Opt(:hvstretch,:notify),
              Header(
                _("Status"),
                _("Read-Only"),
                _("Name"),
                _("Path"),
                _("Guest Access"),
                _("Comment")
              ),
              []
            ),
            HBox(
              PushButton(Id(:add), Ops.add(Label.AddButton, "...")),
              PushButton(Id(:edit), Ops.add(Label.EditButton, "...")),
              PushButton(Id(:delete), Label.DeleteButton),
              HStretch(),
              PushButton(Id(:rename), _("&Rename...")),
              PushButton(Id(:guest), _("Guest Access")),
              PushButton(Id(:toggle), _("&Toggle Status"))
            )
          )
        ),
        HWeight(1, Empty())
      )

      wins_widget = HBox(
        HSpacing(1),
        VBox(
          VSpacing(0.5),
          RadioButtonGroup(
            Id("wins_support"),
            VBox(
              Left(
                RadioButton(
                  Id("wins_server_support"),
                  Opt(:notify),
                  _("WINS Server Support")
                )
              ),
              Left(
                RadioButton(
                  Id("remote_wins_server"),
                  Opt(:notify),
                  _("Remote WINS Server")
                )
              )
            )
          ),
          HBox(HSpacing(3), TextEntry(Id("wins_server_name"), _("Na&me"))),
          VSpacing(1)
        ),
        HSpacing(1)
      )

      wins_via_dhcp = DHCPSupportTerm(Samba.GetDHCP)

      # TRANSLATORS: check box
      wins_host_resolution = Left(
        CheckBox(Id(:wins_dns), _("Use WINS for Hostname Resolution"))
      )

      roles = [
        # translators: combobox item
        Item(Id("STANDALONE"), _("Not a DC")),
        # translators: combobox item
        Item(Id("PDC"), _("Primary (PDC)"))
      ]

      # translators: combobox item
      roles = Builtins.add(roles, Item(Id("BDC"), _("Backup (BDC)")))

      basesettings_widget = Frame(
        _("Base Settings"),
        HBox(
          HSpacing(1),
          VBox(
            # `ComboBox(`id("workgroup_domainname"), `opt(`editable, `hstretch), _("&Workgroup or Domain Name"),
            #	SambaNmbLookup::GetAvailableNeighbours(nil)),
            InputField(
              Id("workgroup_domainname"),
              Opt(:hstretch),
              _("&Workgroup or Domain Name")
            ),
            # translators: combobox label
            ComboBox(
              Id("domain_controller"),
              Opt(:hstretch),
              _("Domain &Controller"),
              roles
            ),
            VStretch()
          ),
          HSpacing(1)
        )
      )

      advanced_settings_widget = MenuButton(
        _("Advanced Settings..."),
        [
          Item(Id(:global_settings), _("&Expert Global Settings")),
          Item(Id(:passdb), _("&User Authentication Sources"))
        ]
      )

      trusted_domains_widget = HBox(
        HWeight(1, Empty()),
        HWeight(
          100,
          VBox(
            VWeight(
              7,
              ReplacePoint(
                Id(:domains_tr),
                SelectionBox(Id("trusted_domains"), _("&Trusted Domains"), [])
              )
            ),
            VWeight(
              1,
              HBox(
                PushButton(Id(:add_domain), Ops.add(Label.AddButton, "...")),
                PushButton(Id(:delete_domain), Label.DeleteButton),
                HStretch()
              )
            ),
            VStretch()
          )
        ),
        HWeight(1, Empty())
      )

      caption = _("Samba Configuration")

      tabs_descr = {
        "startup"  => {
          #tab label
          "header"       => _("Start-&Up"),
          "contents"     => HBox(
            HWeight(2, Empty()),
            HWeight(
              100,
              VBox(
                VSpacing(1),
                "service_widget",
                VSpacing(1),
                "FIREWALL",
                VStretch()
              )
            ),
            HWeight(2, Empty())
          ),
          "widget_names" => ["service_widget", "FIREWALL"]
        },
        "shares"   => {
          "header"       => _("&Shares"),
          "contents"     => VBox(
            VBox("SHARES"),
            HBox(
              HSpacing(1),
              # Bugzilla #143908
              # Bugzilla #144787, comment #43
              SharesTerm(
                {
                  "allow_share"  => @allow_share,
                  "group"        => @shares_group,
                  "max_shares"   => @max_shares,
                  # BNC #579993, Allow guest access
                  "guest_access" => @guest_access
                }
              ),
              HSpacing(1)
            ),
            VSpacing(1)
          ),
          "widget_names" => ["SHARES"]
        },
        "identity" => {
          "header"       => _("I&dentity"),
          "contents"     => HBox(
            "IDENTITY COMMON HELP",
            HWeight(1, Empty()),
            HWeight(
              100,
              VBox(
                VSpacing(0.5),
                VBox(
                  HBox(
                    HWeight(1, VBox("BASE SETTINGS")),
                    HSpacing(0.5),
                    HWeight(
                      1,
                      Frame(
                        _("WINS"),
                        VBox(
                          "WINS SETTINGS",
                          HBox(HSpacing(1), "WINS via DHCP"),
                          HBox(HSpacing(1), "WINS Host Resolution"),
                          VStretch()
                        )
                      )
                    )
                  ),
                  VSpacing(0.5),
                  HBox(
                    HWeight(1, VBox("netbios name", "ADVANCED SETTINGS")),
                    HSpacing(0.5),
                    HWeight(1, Empty())
                  )
                ),
                VStretch()
              )
            ),
            HWeight(1, Empty())
          ),
          "widget_names" => [
            "IDENTITY COMMON HELP",
            "BASE SETTINGS",
            "WINS SETTINGS",
            "WINS via DHCP",
            "WINS Host Resolution",
            "netbios name",
            "ADVANCED SETTINGS"
          ]
        }
      }

      tabs_descr = Builtins.union(
        tabs_descr,
        {
          "trusted_domains_tab" => {
            "header"       => _("&Trusted Domains"),
            "contents"     => VBox("TRUSTED DOMAINS"),
            "widget_names" => ["TRUSTED DOMAINS"]
          },
          "ldap_settings_tab"   => {
            "header"       => _("&LDAP Settings"),
            "contents"     => VBox("LDAP ESSENTIAL"),
            "widget_names" => ["LDAP ESSENTIAL"]
          }
        }
      )

      tabs_widget_descr = {
        "service_widget"       => service_widget.cwm_definition,
        # BNC #247344, BNC #541958 (comment #18)
        "FIREWALL"             => CWMFirewallInterfaces.CreateOpenFirewallWidget(
          {
            # Firewalld default service definition
            "services"        => ["samba"],
            "display_details" => true
          }
        ),
        "SHARES"               => {
          "widget"        => :custom,
          "custom_widget" => shares_widget,
          "init"          => fun_ref(method(:SharesWidgetInit), "void (string)"),
          "handle"        => fun_ref(
            method(:SharesWidgetHandle),
            "symbol (string, map)"
          ),
          "store"         => fun_ref(
            method(:StoreUserShareWidgets),
            "void (string, map)"
          ),
          "help"          => Ops.add(
            Ops.get_string(@HELPS, "smb_conf_tab_shares", ""),
            SharesHelp()
          )
        },
        "IDENTITY COMMON HELP" => {
          "widget"        => :custom,
          "custom_widget" => Empty(),
          "help"          => Ops.get_string(@HELPS, "smb_conf_tab_identity", "")
        },
        "BASE SETTINGS"        => {
          "widget"        => :custom,
          "custom_widget" => basesettings_widget,
          "help"          => Ops.get_string(
            @HELPS,
            "smb_conf_tab_base_settings",
            ""
          ),
          "init"          => fun_ref(
            method(:BaseSettingsWidgetInit),
            "void (string)"
          ),
          "store"         => fun_ref(
            method(:BaseSettingsWidgetStore),
            "void (string, map)"
          )
        },
        "WINS SETTINGS"        => {
          "widget"        => :custom,
          "custom_widget" => wins_widget,
          "help"          => HostsResolutionHelp(),
          "init"          => fun_ref(
            method(:WinsSettingsWidgetInit),
            "void (string)"
          ),
          "store"         => fun_ref(
            method(:WinsSettingsWidgetStore),
            "void (string, map)"
          ),
          "handle"        => fun_ref(
            method(:WinsSettingsWidgetHandle),
            "symbol (string, map)"
          )
        },
        "WINS via DHCP"        => {
          "widget"        => :custom,
          "custom_widget" => wins_via_dhcp,
          "help"          => Ops.get_string(
            @HELPS,
            "smb_conf_tab_wins_via_dhcp",
            ""
          ),
          "init"          => fun_ref(
            method(:WinsViaDHCPWidgetInit),
            "void (string)"
          ),
          "store"         => fun_ref(
            method(:WinsViaDHCPWidgetStore),
            "void (string, map)"
          )
        },
        "WINS Host Resolution" => {
          "widget"        => :custom,
          "custom_widget" => wins_host_resolution,
          "help"          => Ops.get_string(
            @HELPS,
            "smb_conf_tab_wins_host_resolution",
            ""
          ),
          "init"          => fun_ref(
            method(:WinsHostResolutionWidgetInit),
            "void (string)"
          ),
          "store"         => fun_ref(
            method(:WinsHostResolutionWidgetStore),
            "void (string, map)"
          )
        },
        "netbios name"         => {
          "widget" => :textentry,
          "label"  => _("NetBIOS &Hostname"),
          "help"   => Ops.get_string(@HELPS, "smb_conf_tab_netbios_name", ""),
          "init"   => fun_ref(
            method(:GlobalConfigStringWidgetInit),
            "void (string)"
          ),
          "store"  => fun_ref(
            method(:GlobalConfigStringWidgetStore),
            "void (string, map)"
          )
        },
        "ADVANCED SETTINGS"    => {
          "widget"        => :custom,
          "custom_widget" => advanced_settings_widget,
          "help"          => Ops.get_string(
            @HELPS,
            "smb_conf_tab_advanced_settings",
            ""
          ),
          "handle"        => fun_ref(
            method(:AdvancedSettingsWidgetHandle),
            "symbol (string, map)"
          )
        },
        "TRUSTED DOMAINS"      => {
          "widget"        => :custom,
          "custom_widget" => trusted_domains_widget,
          "init"          => fun_ref(
            method(:TrustedDomainsWidgetInit),
            "void (string)"
          ),
          "handle"        => fun_ref(
            method(:TrustedDomainsWidgetHandle),
            "symbol (string, map)"
          ),
          "help"          => Ops.get_string(
            @HELPS,
            "smb_conf_tab_trusted_domains",
            ""
          )
        },
        "LDAP ESSENTIAL"       => CreateSambaLDAPSettingsEssentialWidget()
      }

      widget_descr = {
        "tab" => CWMTab.CreateWidget(
          {
            "tab_order"    => [
              "startup",
              "shares",
              "identity",
              "trusted_domains_tab",
              "ldap_settings_tab"
            ],
            "tabs"         => tabs_descr,
            "widget_descr" => tabs_widget_descr,
            "initial_tab"  => @return_tab,
            "tab_help"     => ""
          }
        )
      }

      contents = VBox("tab", VStretch())

      w = CWM.CreateWidgets(
        ["tab"],
        Convert.convert(
          widget_descr,
          :from => "map",
          :to   => "map <string, map <string, any>>"
        )
      )
      help = CWM.MergeHelps(w)
      contents = CWM.PrepareDialog(contents, w)

      Wizard.SetContentsButtons(
        caption,
        contents,
        help,
        Label.BackButton,
        Label.OKButton
      )

      # BNC #440538
      # Adjusted according to the YaST Style Guide
      Wizard.SetAbortButton(:abort, Label.CancelButton)
      Wizard.HideBackButton

      ret = CWM.Run(
        w,
        { :abort => fun_ref(method(:confirmAbort), "boolean ()") }
      )

      deep_copy(ret)
    end


    # Dialog to configure passdb backends.
    # @return dialog result
    def PassdbDialog
      # dialog caption
      caption = _("User Information Sources")

      w = CWM.CreateWidgets(
        ["passdb_edit"],
        Convert.convert(
          @xx_widgets,
          :from => "map",
          :to   => "map <string, map <string, any>>"
        )
      )

      contents = HBox(
        HSpacing(1),
        VBox(VSpacing(1), Ops.get_term(w, [0, "widget"]) { VSpacing(0) }),
        HSpacing(1)
      )

      help = CWM.MergeHelps(w)

      Wizard.SetContentsButtons(
        caption,
        contents,
        help,
        Label.BackButton,
        Label.OKButton
      )

      #     UI::ReplaceWidget( `id(`_tp_table_repl),
      #         // TRANSLATORS: menu button label for accessing the LDAP-related settings and actions
      #         `MenuButton( "LDAP",
      # 	    // translators: menu item to show a LDAP-related settings
      # 	    [ `item( `id(`ldap), _("Global LDAP Settings") ),
      # 	      // translators: menu item to test the currently selected LDAP url
      # 	      `item( `id(`ldap_test), _("Test LDAP Connection") ),
      # 	    ]
      # 	)
      #     );
      CWM.Run(w, { :abort => fun_ref(method(:confirmAbort), "boolean ()") })
    end


    def EnsureRootAccountDialog
      if SambaRole.GetRole != "PDC" || Mode.autoinst || Mode.test ||
          SambaAccounts.UserExists("root")
        return :ok
      end

      # try to create it

      # first, ask for password
      UI.OpenDialog(
        HVSquash(
          VBox(
            Label(
              _(
                "For a proper function, Samba server needs an\n" +
                  "administrative account (root).\n" +
                  "It will be created now."
              )
            ),
            Password(Id(:passwd1), _("Samba root &Password")),
            Password(Id(:passwd2), _("&Verify Password")),
            HBox(
              PushButton(Id(:ok), Opt(:default), Label.OKButton),
              PushButton(Id(:cancel), Label.CancelButton)
            )
          )
        )
      )
      UI.SetFocus(Id(:passwd1))

      ret = nil
      passwd = nil
      begin
        ret = UI.UserInput
        if ret == :ok
          passwd1 = Convert.to_string(UI.QueryWidget(Id(:passwd1), :Value))
          passwd2 = Convert.to_string(UI.QueryWidget(Id(:passwd2), :Value))
          if passwd1 != passwd2
            # TRANSLATORS: popup error message
            Popup.Error(
              _(
                "The first and the second version\nof the password do not match."
              )
            )
            ret = nil
          else
            passwd = passwd1
          end
        end
      end while ret == nil

      UI.CloseDialog
      return :cancel if ret == :cancel

      if SambaAccounts.UserAdd("root", passwd)
        # TRANSLATORS: popup error message, %1 is a username
        Popup.Error(
          Builtins.sformat(_("Cannot create account for user %1."), "root")
        )
        return :error
      end

      :ok
    end


    def AskJoinDomainDialog
      workgroup = SambaConfig.GlobalGetStr("workgroup", "")
      role = SambaRole.GetRole

      # for autoyast, skip testing
      if Mode.config || role != "MEMBER" && role != "BDC"
        #      (!SambaNmbLookup::IsDomain(workgroup)))
        return :ok
      end

      SambaAD.ReadADS(workgroup)
      SambaAD.ReadRealm
      res = SambaNetJoin.Test(workgroup)
      return :ok if res == true

      # Xtranslators: popup question, The workgroup is a domain in fact and the machine is not a member, ask user what to do.
      # %1 is the domain name
      #    if (!Popup::YesNo(sformat(_("This host is not a member\nof the domain %1.") + "\n\n"
      #        + _("Join the domain %1?") + "\n", workgroup)))
      #    {
      #	return `ok;
      #    }

      user = "Administrator"
      passwd = ""
      UI.OpenDialog(
        VBox(
          # translators: popup to fill in the domain joining info; %1 is the domain name
          Label(
            Ops.add(
              Ops.add(
                Ops.add(
                  Builtins.sformat(
                    _(
                      "Enter the username and the password\nfor joining the domain %1."
                    ),
                    workgroup
                  ),
                  "\n\n"
                ),
                _(
                  "To join the domain anonymously, leave the\ntext entries empty."
                )
              ),
              "\n"
            )
          ),
          # text entry label
          TextEntry(Id(:user), _("&Username"), user),
          # text entry label
          Password(Id(:passwd), _("&Password")),
          HBox(
            # translators: button label to skip joining to domain
            PushButton(Id(:skip), _("Do &Not Join")),
            PushButton(Id(:cancel), Label.CancelButton),
            PushButton(Id(:ok), Opt(:default), Label.OKButton)
          )
        )
      )

      ret = UI.UserInput

      user = Convert.to_string(UI.QueryWidget(Id(:user), :Value))
      passwd = Convert.to_string(UI.QueryWidget(Id(:passwd), :Value))

      UI.CloseDialog

      return :skip if ret == :skip
      return :cancel if ret != :ok

      relname = OSRelease.ReleaseName
      relver = OSRelease.ReleaseVersion
      # try to join the domain
      error = SambaNetJoin.Join(
        workgroup,
        Builtins.tolower(role),
        user,
        passwd,
        "",
        relname,
        relver
      )
      if error != nil
        Popup.Error(error)
        return :error
      end

      # Translators: Information popup, %1 is the name of the domain
      Popup.Message(
        Builtins.sformat(_("Domain %1 joined successfully."), workgroup)
      )
      :ok
    end
  end
end
