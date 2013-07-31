# encoding: utf-8

module Yast
  class YaPIEditSAMConfigurationClient < Client
    def main
      # test for YaPI::Samba::EditSAMConfiguration()
      # $Id$
      # testedfiles: SambaConfig.pm

      Yast.import "SambaConfig"

      Yast.include self, "testsuite.rb"
      Yast.include self, "tests-common.rb"

      SambaConfig.Import(
        {
          "global" => {
            "ldap suffix"      => "dc=another",
            "local master"     => "no",
            "workgroup"        => "Test",
            "domain master"    => "no",
            "ldap admin dn"    => "uid=fool,dc=another",
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

      TEST(lambda do
        YaPI::Samba.EditSAMConfiguration(
          "ldapsam:ldap://localhost",
          {
            "ldap suffix"   => "dc=test,dc=domain",
            "ldap admin dn" => "uid=fool,dc=test,dc=domain"
          }
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

Yast::YaPIEditSAMConfigurationClient.new.main
