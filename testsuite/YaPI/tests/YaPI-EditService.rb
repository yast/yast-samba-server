# encoding: utf-8

module Yast
  class YaPIEditServiceClient < Client
    def main
      # test for Samba::EnableServer( boolean ) - enable/disable smb/nmb service
      # $Id$
      # testedfiles: Samba.ycp Service.ycp SambaServer.ycp Ldap.ycp

      Yast.import "SambaConfig"

      Yast.include self, "testsuite.rb"
      Yast.include self, "tests-common.rb"

      @r = depth_union(@r_common, {})
      @w = depth_union(@w_common, {})
      @x = depth_union(@x_common, {})

      TESTSUITE_INIT([@r, @w, @x], nil)
      Yast.import "YaPI::Samba"

      TEST(lambda { "Enable disabled service" }, [@r, @w, @x], nil)

      # enable service, but it's disabled
      TEST(
        lambda { YaPI::Samba.EditService(true) },
        [
          {
            "init"   => { "scripts" => { "exists" => true } },
            "target" => { "stat" => { 1 => 2 } }
          },
          {},
          { "target" => { "bash_output" => { "exit" => 0, 'stdout'=>'', 'stderr'=>'' }, "bash" => 1 } }
        ],
        nil
      )

      TEST(lambda { "Disable disabled service" }, [@r, @w, @x], nil)

      # disable service, but it's already disabled
      TEST(
        lambda { YaPI::Samba.EditService(false) },
        [
          {
            "init"   => { "scripts" => { "exists" => true } },
            "target" => { "stat" => { 1 => 2 } }
          },
          {},
          { "target" => { "bash_output" => { "exit" => 0, 'stdout'=>'', 'stderr'=>'' }, "bash" => 1 } }
        ],
        nil
      )

      TEST(lambda { "Enable enabled service" }, [@r, @w, @x], nil)

      # enable service, but it's already enabled
      TEST(
        lambda { YaPI::Samba.EditService(true) },
        [
          {
            "init"   => {
              "scripts" => {
                "exists"   => true,
                "runlevel" => {
                  "smb" => { "start" => ["2", "3", "5"] },
                  "nmb" => { "start" => ["2", "3", "5"] }
                }
              }
            },
            "target" => { "stat" => { 1 => 2 } }
          },
          {},
          { "target" => { "bash_output" => { "exit" => 0, 'stdout'=>'', 'stderr'=>'' }, "bash" => 0 } }
        ],
        nil
      )

      TEST(lambda { "Disable enabled service" }, [@r, @w, @x], nil)

      Yast.import "SambaService"

      # disable service, but it's enabled
      TEST(
        lambda { YaPI::Samba.EditService(false) },
        [
          {
            "init"   => {
              "scripts" => {
                "exists"   => true,
                "runlevel" => {
                  "smb" => { "start" => ["2", "3", "5"] },
                  "nmb" => { "start" => ["2", "3", "5"] }
                }
              }
            },
            "target" => { "stat" => { 1 => 2 } }
          },
          {},
          { "target" => {
            "bash_output" => {
              "exit" => 0, 'stdout'=>'', 'stderr'=>''
            },
            "bash" => 0
          }
        }
      ],
      nil
      )

      nil
    end
  end
end

Yast::YaPIEditServiceClient.new.main
