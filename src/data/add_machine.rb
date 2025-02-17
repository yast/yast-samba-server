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

# File:	data/add_machine.ycp
# Package:	Configuration of samba-server
# Authors:	???@suse.??
#
# $Id$
module Yast
  class AddMachineClient < Client
    def main

      Yast.import "YaPI::USERS"
      Yast.import "Service"

      # get the machine name
      @value = Convert.to_string(WFM.Args(0))

      # get the samba configuration

      @bind_dn = GetGlobalVariable("ldap admin dn")
      if @bind_dn == nil
        Builtins.y2error("ldap admin dn not configured")
        return false
      end

      @ldap_suffix = GetGlobalVariable("ldap suffix")
      if @ldap_suffix == nil
        Builtins.y2error("ldap suffix not configured")
        return false
      end

      @ldap_machine_suffix = GetGlobalVariable("ldap machine suffix")
      if @ldap_machine_suffix == nil
        Builtins.y2error("ldap machine suffix not configured")
        return false
      end

      # get the ldap password
      @res = Convert.to_map(
        SCR.Execute(
          path(".target.bash_output"),
          "/usr/bin/tdbdump /etc/samba/secrets.tdb"
        )
      )

      if Ops.get_integer(@res, "exit", -1) != 0
        Builtins.y2error("Cannot execute tdbdump")
        return false
      end

      @output = Ops.get_string(@res, "stdout", "")

      @lines = Builtins.splitstring(@output, "\n")
      @index = -1

      @regexp = Ops.add(
        Ops.add("^key.* = \"SECRETS/LDAP_BIND_PW/", @bind_dn),
        "\"$"
      )

      Builtins.foreach(@lines) do |line|
        @index = Ops.add(@index, 1)
        raise Break if Builtins.regexpmatch(line, @regexp)
      end

      if @index == -1 ||
          Ops.greater_or_equal(@index, Ops.subtract(Builtins.size(@lines), 1))
        # not found
        Builtins.y2error("Cannot get LDAP admin password")
        return false
      end

      @passwd = Ops.get(@lines, Ops.add(@index, 1), "")

      @passwd = Builtins.regexpsub(@passwd, "^data.* = \"(.*)\\\\00\"$", "\\1")

      @config_map = {
        "bind_pw"   => @passwd,
        "bind_dn"   => @bind_dn,
        "user_base" => Ops.add(Ops.add(@ldap_machine_suffix, ","), @ldap_suffix),
        "type"      => "ldap",
        "plugins"   => ["UsersPluginLDAPAll", "UsersPluginSamba"]
      }

      @data_map = {
        "uid"           => @value,
        "givenName"     => "Machine",
        "cn"            => @value,
        "sn"            => "Machine",
        "userPassword"  => "*",
        "loginShell"    => "/bin/false",
        "homeDirectory" => "/var/lib/nobody",
        "create_home"   => false
      }

      # add the user
      Builtins.y2milestone(YaPI::USERS.UserAdd(@config_map, @data_map))

      true
    end

    def GetGlobalVariable(var_name)
      # SCR::Read (.etc.smb.value.global."variable") --> returns list <string>
      tmp_read = Convert.convert(
        SCR.Read(Builtins.add(path(".etc.smb.value.global"), var_name)),
        :from => "any",
        :to   => "list <string>"
      )
      if tmp_read == nil
        return nil
      else
        return Ops.get(tmp_read, 0)
      end
    end
  end
end

Yast::AddMachineClient.new.main
