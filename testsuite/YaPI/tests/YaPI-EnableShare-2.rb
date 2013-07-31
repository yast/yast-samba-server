# encoding: utf-8

module Yast
  class YaPIEnableShare2Client < Client
    def main
      # test for YaPI::Samba::EnablePrinters()
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

      # disable
      TEST(lambda { YaPI::Samba.EnableShare("lp", false) }, [
        @r_common,
        @w_common,
        @x_common
      ], nil)

      nil
    end
  end
end

Yast::YaPIEnableShare2Client.new.main
