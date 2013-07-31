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

# File:	include/samba-options-global.ycp
# Package:	Configuration of samba-server
# Authors:	mlazar@suse.cz
#
# $Id$
module Yast
  module SambaServerSambaOptionsGlobalInclude
    def initialize_samba_server_samba_options_global(include_target)
      textdomain "samba-server"

      @global_option_widgets = {
        "dos charset"                   => { "table" => { "unique" => true } },
        "unix charset"                  => { "table" => { "unique" => true } },
        "display charset"               => { "table" => { "unique" => true } },
        "workgroup"                     => { "table" => { "unique" => true } },
        "realm"                         => { "table" => { "unique" => true } },
        "netbios name"                  => { "table" => { "unique" => true } },
        "netbios aliases"               => { "table" => { "unique" => true } },
        "netbios scope"                 => { "table" => { "unique" => true } },
        "server string"                 => { "table" => { "unique" => true } },
        "interfaces"                    => { "table" => { "unique" => true } },
        "bind interfaces only"          => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "security"                      => { "table" => { "unique" => true } },
        "auth methods"                  => { "table" => { "unique" => true } },
        "encrypt passwords"             => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "update encrypted"              => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "client schannel"               => { "table" => { "unique" => true } },
        "server schannel"               => { "table" => { "unique" => true } },
        "allow trusted domains"         => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "hosts equiv"                   => { "table" => { "unique" => true } },
        "min passwd length"             => { "table" => { "unique" => true } },
        "min password length"           => { "table" => { "unique" => true } },
        "map to guest"                  => { "table" => { "unique" => true } },
        "null passwords"                => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "obey pam restrictions"         => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "password server"               => { "table" => { "unique" => true } },
        "smb passwd file"               => { "table" => { "unique" => true } },
        "private dir"                   => { "table" => { "unique" => true } },
        "passdb backend"                => { "table" => { "unique" => true } },
        "algorithmic rid base"          => { "table" => { "unique" => true } },
        "root directory"                => { "table" => { "unique" => true } },
        "root dir"                      => { "table" => { "unique" => true } },
        "root"                          => { "table" => { "unique" => true } },
        "guest account"                 => { "table" => { "unique" => true } },
        "pam password change"           => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "passwd program"                => { "table" => { "unique" => true } },
        "passwd chat"                   => { "table" => { "unique" => true } },
        "passwd chat debug"             => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "passwd chat timeout"           => { "table" => { "unique" => true } },
        "username map"                  => { "table" => { "unique" => true } },
        "password level"                => { "table" => { "unique" => true } },
        "username level"                => { "table" => { "unique" => true } },
        "unix password sync"            => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "restrict anonymous"            => { "table" => { "unique" => true } },
        "lanman auth"                   => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "ntlm auth"                     => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        ""                              => { "table" => { "unique" => true } },
        "client lanman auth"            => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "client plaintext auth"         => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "preload modules"               => { "table" => { "unique" => true } },
        "log level"                     => { "table" => { "unique" => true } },
        "debuglevel"                    => { "table" => { "unique" => true } },
        "syslog"                        => { "table" => { "unique" => true } },
        "syslog only"                   => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "log file"                      => { "table" => { "unique" => true } },
        "max log size"                  => { "table" => { "unique" => true } },
        "timestamp logs"                => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "debug timestamp"               => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "debug hires timestamp"         => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "debug pid"                     => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "debug uid"                     => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "smb ports"                     => { "table" => { "unique" => true } },
        "protocol"                      => { "table" => { "unique" => true } },
        "large readwrite"               => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "max protocol"                  => { "table" => { "unique" => true } },
        "min protocol"                  => { "table" => { "unique" => true } },
        "read bmpx"                     => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "read raw"                      => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "write raw"                     => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "disable netbios"               => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "acl compatibility"             => { "table" => { "unique" => true } },
        "nt pipe support"               => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "nt status support"             => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "announce version"              => { "table" => { "unique" => true } },
        "announce as"                   => { "table" => { "unique" => true } },
        "max mux"                       => { "table" => { "unique" => true } },
        "max xmit"                      => { "table" => { "unique" => true } },
        "name resolve order"            => { "table" => { "unique" => true } },
        "max ttl"                       => { "table" => { "unique" => true } },
        "max wins ttl"                  => { "table" => { "unique" => true } },
        "min wins ttl"                  => { "table" => { "unique" => true } },
        "time server"                   => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "unix extensions"               => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "use spnego"                    => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "client signing"                => { "table" => { "unique" => true } },
        "server signing"                => { "table" => { "unique" => true } },
        "client use spnego"             => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "change notify timeout"         => { "table" => { "unique" => true } },
        "deadtime"                      => { "table" => { "unique" => true } },
        "getwd cache"                   => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "keepalive"                     => { "table" => { "unique" => true } },
        "kernel change notify"          => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "lpq cache time"                => { "table" => { "unique" => true } },
        "max smbd processes"            => { "table" => { "unique" => true } },
        "paranoid server security"      => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "max disk size"                 => { "table" => { "unique" => true } },
        "max open files"                => { "table" => { "unique" => true } },
        "socket options"                => { "table" => { "unique" => true } },
        "use mmap"                      => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "hostname lookups"              => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "name cache timeout"            => { "table" => { "unique" => true } },
        "load printers"                 => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "printcap name"                 => { "table" => { "unique" => true } },
        "printcap"                      => { "table" => { "unique" => true } },
        "disable spoolss"               => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "enumports command"             => { "table" => { "unique" => true } },
        "addprinter command"            => { "table" => { "unique" => true } },
        "deleteprinter command"         => { "table" => { "unique" => true } },
        "show add printer wizard"       => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        ""                              => { "table" => { "unique" => true } },
        "mangling method"               => { "table" => { "unique" => true } },
        "mangle prefix"                 => { "table" => { "unique" => true } },
        "stat cache"                    => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "machine password timeout"      => { "table" => { "unique" => true } },
        "add user script"               => { "table" => { "unique" => true } },
        "delete user script"            => { "table" => { "unique" => true } },
        "add group script"              => { "table" => { "unique" => true } },
        "delete group script"           => { "table" => { "unique" => true } },
        "add user to group script"      => { "table" => { "unique" => true } },
        "delete user from group script" => { "table" => { "unique" => true } },
        "set primary group script"      => { "table" => { "unique" => true } },
        "add machine script"            => { "table" => { "unique" => true } },
        "shutdown script"               => { "table" => { "unique" => true } },
        "abort shutdown script"         => { "table" => { "unique" => true } },
        "logon script"                  => { "table" => { "unique" => true } },
        "logon path"                    => { "table" => { "unique" => true } },
        "logon drive"                   => { "table" => { "unique" => true } },
        "logon home"                    => { "table" => { "unique" => true } },
        "domain logons"                 => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "os level"                      => { "table" => { "unique" => true } },
        "lm announce"                   => { "table" => { "unique" => true } },
        "lm interval"                   => { "table" => { "unique" => true } },
        "preferred master"              => { "table" => { "unique" => true } },
        "prefered master"               => { "table" => { "unique" => true } },
        "local master"                  => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "domain master"                 => { "table" => { "unique" => true } },
        "browse list"                   => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "enhanced browsing"             => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "dns proxy"                     => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "wins proxy"                    => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "wins server"                   => { "table" => { "unique" => true } },
        "wins support"                  => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "wins hook"                     => { "table" => { "unique" => true } },
        "wins partners"                 => { "table" => { "unique" => true } },
        "kernel oplocks"                => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "lock spin count"               => { "table" => { "unique" => true } },
        "lock spin time"                => { "table" => { "unique" => true } },
        "oplock break wait time"        => { "table" => { "unique" => true } },
        "ldap server"                   => { "table" => { "unique" => true } },
        "ldap port"                     => { "table" => { "unique" => true } },
        "ldap suffix"                   => { "table" => { "unique" => true } },
        "ldap machine suffix"           => { "table" => { "unique" => true } },
        "ldap user suffix"              => { "table" => { "unique" => true } },
        "ldap group suffix"             => { "table" => { "unique" => true } },
        "ldap idmap suffix"             => { "table" => { "unique" => true } },
        # There is no such option, bug 169194
        #"ldap filter" : $[
        #	"table" : $[
        #		"unique" : true,
        #	],
        #],
        "ldap admin dn"                 => {
          "table" => { "unique" => true }
        },
        "ldap ssl"                      => { "table" => { "unique" => true } },
        "ldap passwd sync"              => { "table" => { "unique" => true } },
        "ldap delete dn"                => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "ldap replication sleep"        => { "table" => { "unique" => true } },
        "add share command"             => { "table" => { "unique" => true } },
        "change share command"          => { "table" => { "unique" => true } },
        "delete share command"          => { "table" => { "unique" => true } },
        "config file"                   => { "table" => { "unique" => true } },
        "preload"                       => { "table" => { "unique" => true } },
        "auto services"                 => { "table" => { "unique" => true } },
        "lock directory"                => { "table" => { "unique" => true } },
        "lock dir"                      => { "table" => { "unique" => true } },
        "pid directory"                 => { "table" => { "unique" => true } },
        "utmp directory"                => { "table" => { "unique" => true } },
        "wtmp directory"                => { "table" => { "unique" => true } },
        "utmp"                          => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "default service"               => { "table" => { "unique" => true } },
        "default"                       => { "table" => { "unique" => true } },
        "message command"               => { "table" => { "unique" => true } },
        "dfree command"                 => { "table" => { "unique" => true } },
        "get quota command"             => { "table" => { "unique" => true } },
        "set quota command"             => { "table" => { "unique" => true } },
        "remote announce"               => { "table" => { "unique" => true } },
        "remote browse sync"            => { "table" => { "unique" => true } },
        "socket address"                => { "table" => { "unique" => true } },
        "homedir map"                   => { "table" => { "unique" => true } },
        "afs username map"              => { "table" => { "unique" => true } },
        "time offset"                   => { "table" => { "unique" => true } },
        "NIS homedir"                   => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "panic action"                  => { "table" => { "unique" => true } },
        "host msdfs"                    => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "enable rid algorithm"          => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "idmap backend"                 => { "table" => { "unique" => true } },
        "idmap uid"                     => { "table" => { "unique" => true } },
        "winbind uid"                   => { "table" => { "unique" => true } },
        "idmap gid"                     => { "table" => { "unique" => true } },
        "winbind gid"                   => { "table" => { "unique" => true } },
        "template primary group"        => { "table" => { "unique" => true } },
        "template homedir"              => { "table" => { "unique" => true } },
        "template shell"                => { "table" => { "unique" => true } },
        "winbind separator"             => { "table" => { "unique" => true } },
        "winbind cache time"            => { "table" => { "unique" => true } },
        "winbind enable local accounts" => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "winbind enum users"            => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "winbind enum groups"           => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "winbind use default domain"    => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "winbind trusted domains only"  => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        },
        "winbind nested groups"         => {
          "table" => { "unique" => true },
          "popup" => { "widget" => :checkbox }
        }
      }
    end
  end
end
