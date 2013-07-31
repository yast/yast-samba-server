# encoding: utf-8

module Yast
  class YaPIEditServerDescriptionClient < Client
    def main
      # test for YaPI::Samba::EditServerDescription()
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
            "server string"    => "This is test",
            "security"         => "user",
            "preferred master" => "yes",
            "domain logons"    => "no",
            "local master"     => "no"
          }
        }
      )

      Yast.import "YaPI::Samba"

      TEST(lambda do
        YaPI::Samba.EditServerDescription(
          "AND NOW FOR SOMETHING COMPLETELY DIFFERENT"
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

Yast::YaPIEditServerDescriptionClient.new.main
