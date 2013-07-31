# encoding: utf-8

module Yast
  class YaPIAddShareClient < Client
    def main
      # test for YaPI::Samba::AddShare()
      # $Id$
      # testedfiles: SambaConfig.pm

      Yast.import "SambaConfig"

      Yast.include self, "testsuite.rb"
      Yast.include self, "tests-common.rb"

      SambaConfig.Import(
        {
          "global" => {
            "workgroup"        => "Test",
            "domain master"    => "no",
            "security"         => "user",
            "preferred master" => "yes",
            "domain logons"    => "no",
            "local master"     => "no"
          }
        }
      )

      Yast.import "YaPI::Samba"

      TEST(lambda do
        YaPI::Samba.AddShare(
          "test",
          { "path" => "/home/test", "printable" => "no" }
        )
      end, [
        @r_common,
        @w_common,
        @x_common
      ], nil)

      nil
    end
  end
end

Yast::YaPIAddShareClient.new.main
