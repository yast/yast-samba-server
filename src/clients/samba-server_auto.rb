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

# File:	clients/samba-server_auto.ycp
# Package:	Configuration of samba-server
# Summary:	Client for autoinstallation
# Authors:	Stanislav Visnovsky <visnov@suse.cz>
#
# $Id$
#
# This is a client for autoinstallation. It takes its arguments,
# goes through the configuration and return the setting.
# Does not do any changes to the configuration.

# @param function to execute
# @param map/list of samba-server settings
# @return [Hash] edited settings, Summary or boolean on success depending on called function
# @example map mm = $[ "FAIL_DELAY" : "77" ];
# @example map ret = WFM::CallFunction ("samba-server_auto", [ "Summary", mm ]);
module Yast
  class SambaServerAutoClient < Client
    def main
      Yast.import "UI"

      textdomain "samba-server"

      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("Samba-server auto started")

      Yast.import "SambaServer"
      Yast.include self, "samba-server/wizards.rb"

      @ret = nil
      @func = ""
      @param = {}

      # Check arguments
      if Ops.greater_than(Builtins.size(WFM.Args), 0) &&
          Ops.is_string?(WFM.Args(0))
        @func = Convert.to_string(WFM.Args(0))
        if Ops.greater_than(Builtins.size(WFM.Args), 1) &&
            Ops.is_map?(WFM.Args(1))
          @param = Convert.to_map(WFM.Args(1))
        end
      end
      Builtins.y2debug("func=%1", @func)
      Builtins.y2debug("param=%1", @param)

      # Create a summary
      if @func == "Summary"
        @ret = SambaServer.Summary
      # Reset configuration
      elsif @func == "Reset"
        SambaServer.Import({})
        @ret = {}
      # Change configuration (run AutoSequence)
      elsif @func == "Change"
        @ret = SambaServerAutoSequence()
      # Import configuration
      elsif @func == "Import"
        @ret = SambaServer.Import(@param)
      # Return required packages
      elsif @func == "Packages"
        @ret = SambaServer.AutoPackages
      # Return actual state
      elsif @func == "Export"
        @ret = SambaServer.Export
      # Read current state
      elsif @func == "Read"
        Yast.import "Progress"
        @po = Progress.set(false)
        @ret = SambaServer.Read
        Progress.set(@po)
      # Write givven settings
      elsif @func == "Write"
        Yast.import "Progress"
        @po = Progress.set(false)
        @ret = SambaServer.Write(true)
        Progress.set(@po)
      # Return if configuration  was changed
      # return boolean
      elsif @func == "GetModified"
        @ret = SambaServer.GetModified
      # Set modified flag
      # return boolean
      elsif @func == "SetModified"
        SambaServer.SetModified
        @ret = true
      else
        Builtins.y2error("Unknown function: %1", @func)
        @ret = false
      end

      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("Samba-server auto finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret) 

      # EOF
    end
  end
end

Yast::SambaServerAutoClient.new.main
