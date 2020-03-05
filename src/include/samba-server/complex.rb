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

# File:	include/samba-server/complex.ycp
# Package:	Configuration of samba-server
# Summary:	Dialogs definitions
# Authors:	Stanislav Visnovsky <visnov@suse.cz>
#		Lukas Ocilka <locilka@suse.cz>
#
# $Id$

require "yast2/system_service"
require "yast2/compound_service"

module Yast
  module SambaServerComplexInclude
    def initialize_samba_server_complex(include_target)
      textdomain "samba-server"

      Yast.import "Wizard"

      Yast.import "SambaServer"
      Yast.import "SambaService"
      Yast.import "Progress"
      Yast.import "Report"
      Yast.import "FileUtils"
      Yast.import "Popup"
      Yast.import "Mode"

      Yast.include include_target, "samba-server/helps.rb"
    end

    # Services to configure
    #
    # @return [Yast2::CompoundService]
    def services
      @services ||= Yast2::CompoundService.new(
        Yast2::SystemService.find("nmb"),
        Yast2::SystemService.find("smb")
      )
    end

    # Read settings dialog
    # @return `abort if aborted and `next otherwise
    def ReadDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "read", ""))
      ret = SambaServer.Read
      ret ? :next : :abort
    end

    # replace with Progress::status() after accepted into the build
    # Function returns current progress status
    def ProgressStatus
      # set new progress
      old_progress = Progress.set(false)
      # set old progress back
      Progress.set(old_progress)
      # return current progress
      old_progress
    end

    # Write settings dialog
    #
    # @return [Symbol] :next when service is saved successfully
    #                  :abort otherwise
    def WriteDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "write", ""))
      # Bugzilla #120080 - 'reload' instead of 'restart'
      # If there some connected users, SAMBA is running and should be running
      # also after the Write() operation and the Progress was turned on before
      # Writing SAMBA conf
      switch_to_reload = need_to_restart? && connected_users? && ProgressStatus()

      ret = save_status(switch_to_reload)

      # If popup should be shown and SAMBA is still/again running
      if switch_to_reload && SambaService.GetServiceRunning
        # TRANSLATORS: a popup message
        Report.Message(
          _(
            "Because users are currently connected to this Samba server,\n" +
              "the server configuration has been reloaded instead of restarted.\n" +
              "To confirm that all settings are applied despite possibly disconnecting the users,\n" +
              "run 'systemctl restart smb' and 'systemctl restart nmb'"
          )
        )
      end
      ret ? :next : :abort
    end

    # Convenience method to check whether a restart or reload should be used
    # after writing the configuration
    #
    # @return [Boolean] true if the service is running; false otherwise
    def need_to_restart?
      SambaService.GetServiceRunning
    end

    # Convenience method to check whether there are users connected to samba
    # service or not
    #
    # @return [Boolean] true if some user is connected to the service; false
    #   otherwise
    def connected_users?
      connected_users = SambaService.ConnectedUsers.count
      Builtins.y2milestone("Number of connected users: %1", connected_users)
      connected_users > 0
    end

    # Saves service status (start mode and starts/stops the service)
    #
    # @param switch_to_reload [Boolean] indicates if restart action must be
    #   replaced with reload. See the Bugzilla #120080 stated in #WriteDialog
    #   comments
    #
    # @return [Boolean] true if service is saved successfully; false otherwise
    def save_status(switch_to_reload)
      return false unless SambaServer.Write(false)
      services.reload if services.action == :restart && switch_to_reload
      services.save
    end
  end
end
