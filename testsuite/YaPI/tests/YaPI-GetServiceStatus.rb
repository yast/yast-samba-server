# encoding: utf-8

module Yast
  class YaPIGetServiceStatusClient < Client
    def main
      # test for Samba::EnableServer( boolean ) - enable/disable smb/nmb service
      # $Id$

      Yast.import "SambaConfig"

      Yast.include self, "testsuite.rb"
      Yast.include self, "tests-common.rb"

      @r = depth_union(@r_common, {})
      @w = depth_union(@w_common, {})
      @x = depth_union(@x_common, {})

      TESTSUITE_INIT([@r, @w, @x], nil)
      Yast.import "YaPI::Samba"

      TEST(lambda { "Disabled service" }, [@r, @w, @x], nil)

      # disabled service
      TEST(
        lambda { YaPI::Samba.GetServiceStatus },
        [
          {
            "init"   => { "scripts" => { "exists" => true } },
            "target" => {
              "tmpdir" => "/tmp",
              # FileUtils::Exists returns true
              "stat"   => { 1 => 2 }
            }
          },
          {},
          { "target" => { "bash" => 1 } }
        ],
        nil
      )

      TEST(lambda { "Enabled service" }, [@r, @w, @x], nil)

      # enabled service
      TEST(
        lambda { YaPI::Samba.GetServiceStatus },
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
          { "target" => { "bash" => 0 } }
        ],
        nil
      )

      nil
    end
  end
end

Yast::YaPIGetServiceStatusClient.new.main
