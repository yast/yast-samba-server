# encoding: utf-8

module Yast
  class YaPIEditShareClient < Client
    def main
      # test for YaPI::Samba::EditShare()
      # $Id$
      # testedfiles: SambaConfig.pm

      Yast.import "SambaConfig"

      Yast.include self, "testsuite.rb"
      Yast.include self, "tests-common.rb"

      SambaConfig.Import(
        {
          "global" => {
            "_modified"        => "1",
            "workgroup"        => "Test",
            "domain master"    => "no",
            "security"         => "user",
            "preferred master" => "yes",
            "domain logons"    => "no",
            "local master"     => "no"
          },
          "lp"     => {
            "_modified" => "1",
            "comment"   => "testing printer",
            "printable" => "yes",
            "path"      => "/var/spool/lp"
          }
        }
      )

      Yast.import "YaPI::Samba"

      TEST(lambda do
        YaPI::Samba.EditShare(
          "lp",
          {
            "comment"   => "now it's a production printer",
            "path"      => "/var/spool/lp",
            "printable" => "yes"
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

Yast::YaPIEditShareClient.new.main
