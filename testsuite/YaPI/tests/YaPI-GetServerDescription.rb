# encoding: utf-8

module Yast
  class YaPIGetServerDescriptionClient < Client
    def main
      # test for YaPI::Samba::GetServerDescription()
      # $Id$
      # testedfiles: Dummy.ycp

      Yast.import "SambaConfig"

      Yast.include self, "testsuite.rb"
      Yast.include self, "tests-common.rb"

      SambaConfig.Import(
        {
          "global" => {
            "workgroup"        => "Test",
            "domain master"    => "no",
            "server string"    => "This is test",
            "security"         => "user",
            "preferred master" => "yes",
            "domain logons"    => "no",
            "local master"     => "no"
          }
        }
      )

      Yast.import "YaPI::Samba"

      TEST(lambda { YaPI::Samba.GetServerDescription }, [
        @r_common,
        @w_common,
        @x_common
      ], nil)

      nil
    end
  end
end

Yast::YaPIGetServerDescriptionClient.new.main
