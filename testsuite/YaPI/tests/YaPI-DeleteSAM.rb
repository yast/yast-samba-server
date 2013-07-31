# encoding: utf-8

module Yast
  class YaPIDeleteSAMClient < Client
    def main
      # test for YaPI::Samba::DeleteSAM()
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

      TEST(lambda { YaPI::Samba.DeleteSAM("smbpasswd") }, [
        @r_common,
        @w_common,
        @x_common
      ], nil)

      nil
    end
  end
end

Yast::YaPIDeleteSAMClient.new.main
