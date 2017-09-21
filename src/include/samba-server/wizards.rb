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

# File:	include/samba-server/wizards.ycp
# Package:	Configuration of samba-server
# Summary:	Wizards definitions
# Authors:	Stanislav Visnovsky <stanislav.visnovsky@suse.cz>
#
# $Id$
module Yast
  module SambaServerWizardsInclude
    def initialize_samba_server_wizards(include_target)
      Yast.import "UI"

      textdomain "samba-server"

      Yast.import "Sequencer"
      Yast.import "Wizard"
      Yast.import "Label"
      Yast.import "Mode"

      Yast.import "SambaServer"

      Yast.include include_target, "samba-server/complex.rb"
      Yast.include include_target, "samba-server/dialogs.rb"
    end

    # Main workflow of the samba-server configuration
    # @return sequence result
    def MainSequence
      aliases = {
        "inst_step1"          => lambda { Installation_Step1() },
        "conf_tab"            => lambda { Installation_Conf_Tab() },
        "share_edit"          => lambda { EditShareDialog() },
        "share_add"           => lambda { AddShareDialog() },
        "passdb_edit"         => lambda { PassdbDialog() },
        "global_settings"     => lambda { GlobalSettingsDialog() },
        "ensure_root_account" => lambda { EnsureRootAccountDialog() },
        "ask_join_domain"     => lambda { AskJoinDomainDialog() }
      }

      sequence = {
        "ws_start"            => "inst_step1",
        "inst_step1"          => {
          :cancel => :cancel,
          :abort  => :abort,
          :next   => "conf_tab"
        },
        "conf_tab"            => {
          :cancel          => :cancel,
          :abort           => :abort,
          :add             => "share_add",
          :edit            => "share_edit",
          :passdb          => "passdb_edit",
          :global_settings => "global_settings",
          :next            => "ask_join_domain"
        },
        "ask_join_domain"     => {
          :cancel => "conf_tab",
          :error  => "conf_tab",
          :skip   => :finish,
          :abort  => :abort,
          :ok     => "ensure_root_account"
        },
        "ensure_root_account" => {
          :cancel => "conf_tab",
          :back   => "conf_tab",
          :abort  => :abort,
          :ok     => :finish
        },
        "global_settings"     => {
          :cancel => :cancel,
          :abort  => :abort,
          :next   => "conf_tab"
        },
        "share_edit"          => {
          :cancel => :cancel,
          :abort  => :abort,
          :next   => "conf_tab"
        },
        "share_add"           => {
          :cancel => :cancel,
          :abort  => :abort,
          :next   => "conf_tab"
        },
        "passdb_edit"         => {
          :abort  => :abort,
          :cancel => :cancel,
          :next   => "conf_tab"
        }
      }

      # setup the abort function
      #    SambaServer::AbortFunction = SambaServer::ServerReallyAbort;

      # run wizard only first time and not in autoyast
      if Mode.config || SambaServer.Configured
        Ops.set(sequence, "ws_start", "conf_tab")

        @return_tab = "shares" if !Mode.config
      end

      ret = Sequencer.Run(aliases, sequence)

      deep_copy(ret)
    end

    # Whole configuration of samba-server
    # @return sequence result
    def SambaServerSequence
      aliases = {
        "read"  => [lambda { ReadDialog() }, true],
        "main"  => lambda { MainSequence() },
        "write" => [lambda { WriteDialog() }, true]
      }

      sequence = {
        "ws_start" => "read",
        "read"     => { :abort => :abort, :next => "main" },
        "main"     => {
          :cancel => :abort,
          :abort  => :abort,
          :finish => "write"
        },
        "write"    => { :abort => :abort, :next => :next }
      }

      Wizard.CreateDialog
      Wizard.SetDesktopTitleAndIcon("samba-server")

      ret = Sequencer.Run(aliases, sequence)

      UI.CloseDialog
      deep_copy(ret)
    end

    # Whole configuration of samba-server but without reading and writing.
    # For use with autoinstallation.
    # @return sequence result
    def SambaServerAutoSequence
      # Initialization dialog caption
      caption = _("Samba Server Configuration")
      # Initialization dialog contents
      contents = Label(_("Initializing..."))

      Wizard.CreateDialog
      Wizard.SetContentsButtons(
        caption,
        contents,
        "",
        Label.BackButton,
        Label.NextButton
      )

      ret = MainSequence()

      UI.CloseDialog
      deep_copy(ret)
    end
  end
end
