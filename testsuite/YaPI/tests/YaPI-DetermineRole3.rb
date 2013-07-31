# encoding: utf-8

module Yast
  class YaPIDetermineRole3Client < Client
    def main
      # test for SambaServer::DetermineRole() for BDC
      # $Id$
      # testedfiles: Samba.ycp Service.ycp SambaServer.ycp Ldap.ycp

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
            "domain logons"    => "yes",
            "local master"     => "yes"
          }
        }
      )

      Yast.import "YaPI::Samba"

      TEST(lambda { YaPI::Samba.DetermineRole }, [
        @r_common,
        @w_common,
        @x_common
      ], nil)

      nil
    end
  end
end

Yast::YaPIDetermineRole3Client.new.main
