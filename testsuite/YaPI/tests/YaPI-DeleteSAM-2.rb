# encoding: utf-8

module Yast
  class YaPIDeleteSAM2Client < Client
    def main
      # testedfiles: SambaConfig.pm

      # test for YaPI::Samba::DeleteSAM()
      # $Id$

      Yast.import "SambaConfig"

      Yast.include self, "testsuite.rb"
      Yast.include self, "tests-common.rb"

      SambaConfig.Import(
        {
          "global" => {
            "workgroup"        => "Test",
            "domain master"    => "no",
            "security"         => "user",
            "passdb backend"   => "smbpasswd ldapsam:ldap://localhost",
            "preferred master" => "yes",
            "local master"     => "no",
            "domain logons"    => "no"
          },
          "lp"     => {
            "comment"   => "testing printer",
            "printable" => "yes",
            "path"      => "/var/spool/lp"
          }
        }
      )

      Yast.import "YaPI::Samba"

      TEST(lambda { YaPI::Samba.DeleteSAM("ldapsam:ldap://localhost") }, [
        @r_common,
        @w_common,
        @x_common
      ], nil)

      nil
    end
  end
end

Yast::YaPIDeleteSAM2Client.new.main
