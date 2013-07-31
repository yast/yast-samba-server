# encoding: utf-8

module Yast
  class YaPIAddSAM2Client < Client
    def main
      # test for YaPI::Samba::AddSAM()
      # $Id$

      # testedfiles: SambaConfig.pm

      Yast.import "SambaConfig"

      Yast.include self, "testsuite.rb"
      Yast.include self, "tests-common.rb"

      Yast.import "YaPI::Samba"

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
          }
        }
      )


      # add as non-default
      TEST(lambda { YaPI::Samba.AddSAM("smbpasswd:/var/lib/smbusers", false) }, [
        @r_common,
        @w_common,
        @x_common
      ], nil)

      nil
    end
  end
end

Yast::YaPIAddSAM2Client.new.main
