# encoding: utf-8

module Yast
  class YaPIGetSAMBackendsClient < Client
    def main
      # test for YaPI::Samba::GetSAMBackends()
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
            "security"         => "user",
            "passdb backend"   => "smbpassd ldapsam:ldaps://localhost",
            "preferred master" => "yes",
            "local master"     => "no",
            "domain logons"    => "no"
          }
        }
      )

      Yast.import "YaPI::Samba"

      TEST(lambda { YaPI::Samba.GetSAMBackends }, [
        @r_common,
        @w_common,
        @x_common
      ], nil)

      nil
    end
  end
end

Yast::YaPIGetSAMBackendsClient.new.main
