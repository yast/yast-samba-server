# encoding: utf-8

module Yast
  class YaPIGetSAMConfigurationClient < Client
    def main
      # test for YaPI::Samba::EnablePrinters()
      # $Id$
      # testedfiles: Samba.ycp Service.ycp SambaServer.ycp Ldap.ycp

      Yast.import "SambaConfig"

      Yast.include self, "testsuite.rb"
      Yast.include self, "tests-common.rb"

      SambaConfig.Import(
        {
          "global" => {
            "ldap suffix"      => "dc=test,dc=domain",
            "local master"     => "no",
            "workgroup"        => "Test",
            "domain master"    => "no",
            "ldap admin dn"    => "uid=fool,dc=test,dc=domain",
            "security"         => "user",
            "preferred master" => "yes",
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

      TEST(lambda { YaPI::Samba.GetSAMConfiguration("ldapsam:ldap://localhost") }, [
        @r_common,
        @w_common,
        @x_common
      ], nil)

      nil
    end
  end
end

Yast::YaPIGetSAMConfigurationClient.new.main
