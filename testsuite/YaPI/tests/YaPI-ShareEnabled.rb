# encoding: utf-8

module Yast
  class YaPIShareEnabledClient < Client
    def main
      # test for YaPI::Samba::GetShareEnabled()
      # $Id$
      # testedfiles: Samba.ycp Service.ycp SambaServer.ycp Ldap.ycp

      Yast.import "SambaConfig"

      Yast.include self, "testsuite.rb"
      Yast.include self, "tests-common.rb"

      SambaConfig.Import(
        {
          "lp2"    => {
            "comment"   => "testing printer",
            "printable" => "yes",
            "path"      => "/var/spool/lp"
          },
          "global" => {
            "workgroup"        => "Test",
            "domain master"    => "no",
            "security"         => "user",
            "preferred master" => "yes",
            "domain logons"    => "no",
            "local master"     => "no"
          },
          "lp"     => {
            "comment"   => "testing printer",
            "printable" => "yes",
            "path"      => "/var/spool/lp"
          }
        }
      )

      Yast.import "YaPI::Samba"

      TEST(lambda { YaPI::Samba.GetShareEnabled("lp") }, [
        @r_common,
        @w_common,
        @x_common
      ], nil)
      TEST(lambda { YaPI::Samba.GetShareEnabled("lp2") }, [
        @r_common,
        @w_common,
        @x_common
      ], nil)

      nil
    end
  end
end

Yast::YaPIShareEnabledClient.new.main
