# encoding: utf-8

module Yast
  class YaPIEditServerAsStandaloneClient < Client
    def main
      # test for YaPI::Samba::EditServerAsStandalone()
      # $Id$
      # testedfiles: SambaConfig.pm

      Yast.import "SambaConfig"

      Yast.include self, "testsuite.rb"
      Yast.include self, "tests-common.rb"

      @r = depth_union(
        @r_common,
        { "etc" => { "nsswitch_conf" => { "passwd" => "", "group" => "" } } }
      )

      Yast.import "YaPI::Samba"

      SambaConfig.Import(
        {
          "global" => {
            "workgroup"        => "Test",
            "domain master"    => "no",
            "security"         => "user",
            "preferred master" => "yes",
            "domain logons"    => "no",
            "local master"     => "no"
          }
        }
      )

      TEST(lambda { YaPI::Samba.EditServerAsStandalone }, [
        @r,
        @w_common,
        @x_common
      ], nil)

      nil
    end
  end
end

Yast::YaPIEditServerAsStandaloneClient.new.main
