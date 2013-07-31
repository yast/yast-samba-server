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

      Yast.include include_target, "samba-server/helps.rb"
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
    # @return `abort if aborted and `next otherwise
    def WriteDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "write", ""))
      # Bugzilla #120080 - 'reload' instead of 'restart'
      # If there some connected users, SAMBA is running and should be running also after the Write() operation
      #    and the Progress was turned on before Writing SAMBA conf
      connected_users = SambaService.ConnectedUsers
      Builtins.y2milestone(
        "Number of connected users: %1",
        Builtins.size(connected_users)
      )
      report_restart_popup = Ops.greater_than(Builtins.size(connected_users), 0) &&
        SambaService.GetServiceRunning &&
        SambaService.GetServiceAutoStart &&
        ProgressStatus()

      ret = SambaServer.Write(false)

      # If popup should be shown and SAMBA is still/again running
      if report_restart_popup && SambaService.GetServiceRunning
        # TRANSLATORS: a popup message
        Report.Message(
          _(
            "Because users are currently connected to this Samba server,\n" +
              "the server configuration has been reloaded instead of restarted.\n" +
              "To confirm that all settings are applied despite possibly disconnecting the users,\n" +
              "run '/etc/init.d/smb restart' and '/etc/init.d/nmb restart'"
          )
        )
      end
      ret ? :next : :abort
    end
  end
end
