# encoding: utf-8

module Yast
  class YaPIGetAllPrintersClient < Client
    def main
      # test for YaPI::Samba::GetAllPrinters()
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
            "domain logons"    => "no",
            "local master"     => "no"
          },
          "home"   => { "comment" => "All homes", "path" => "/home" },
          "tmp"    => { "guest ok" => "yes", "path" => "/tmp" },
          "lp"     => {
            "comment"   => "testing printer",
            "printable" => "yes",
            "path"      => "/var/spool/lp"
          }
        }
      )

      Yast.import "YaPI::Samba"

      TEST(lambda { YaPI::Samba.GetAllPrinters }, [
        @r_common,
        @w_common,
        @x_common
      ], nil)

      nil
    end
  end
end

Yast::YaPIGetAllPrintersClient.new.main
