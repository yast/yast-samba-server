# encoding: utf-8

module Yast
  module TestsCommonInclude
    def initialize_tests_common(include_target)
      Yast.import "Mode"
      Mode.SetTest("testsuite")

      @r_common = {
        "passwd"    => { "passwd" => { "pluslines" => [""] } },
        "product"   => {
          "features" => {
            "USE_DESKTOP_SCHEDULER" => "yes",
            "IO_SCHEDULER"          => "yes",
            "UI_MODE"               => "expert",
            "ENABLE_AUTOLOGIN"      => "no",
            "EVMS_CONFIG"           => "no"
          }
        },
        "target"    => {
          "tmpdir" => "/tmp",
          "stat"   => { "xxx" => "yyy" },
          "string" => "fake string\n",
          "size"   => "0"
        },
        "etc"       => {
          "nsswitch_conf" => {
            "passwd"        => "file",
            "group"         => "file",
            "passwd_compat" => nil,
            "group_compat"  => nil
          },
          "ldap_conf"     => { "v" => "3" },
          "hosts"         => { "h" => "987" },
          "install_inf"   => { "i" => "i" },
          "resolv_conf"   => {
            "nameserver" => ["fake name server"],
            "search"     => ["fake search"],
            "domain"     => "fake.domain",
            "process"    => ""
          }
        },
        "ldap"      => {
          "search" => { "fake dn" => { "a2" => "x2" } },
          "error"  => { "msg" => "FAKE ERROR MESSAGE" }
        },
        "sysconfig" => {
          "displaymanager" => { "DISPLAYMANAGER" => "fake display manager" },
          "network"        => {
            "config" => { "a1" => "x" },
            "dhcp"   => { "a1" => "y" }
          },
          "ldap"           => {
            "BASE_CONFIG_DN" => "ou=suseconfig,ou=testsuite,o=suse,c=cz",
            "FILE_SERVER"    => "No",
            "BIND_DN"        => "ou=testsuite,o=suse,c=cz"
          }
        },
        "init"      => { "scripts" => { "exists" => true, "runlevel" => {} } },
        "target"    => { "tmpdir" => "/tmp" }
      }

      @w_common = { "etc" => { "smb" => true } }

      @x_common = {
        "passwd"     => { "init" => true },
        "target"     => {
          "bash"        => 1,
          "bash_output" => {
            "stdout" => "test std out",
            "exit"   => "0",
            "stderr" => "test std error"
          }
        },
        "background" => { "run_output" => true },
        "ldap"       => true
      }
    end

    def depth_union(a, b)
      a = deep_copy(a)
      b = deep_copy(b)
      result = deep_copy(a)
      Builtins.foreach(
        Convert.convert(b, :from => "map", :to => "map <string, any>")
      ) do |key, val|
        if Ops.is_map?(val) && Ops.is_map?(Ops.get(a, key))
          Ops.set(
            result,
            key,
            depth_union(Ops.get_map(a, key, {}), Ops.get_map(b, key, {}))
          )
        elsif Ops.is_list?(val) && Ops.is_list?(Ops.get(a, key))
          Ops.set(
            result,
            key,
            Builtins.union(Ops.get_list(a, key, []), Ops.get_list(b, key, []))
          )
        else
          Ops.set(result, key, val)
        end
      end
      deep_copy(result)
    end
  end
end
