# encoding: utf-8

module Yast
  class SambaTrustDomClient < Client
    def main
      #testedfiles: SambaTrustDom.pm

      Yast.include self, "testsuite.rb"

      @READ = {}
      @WRITE = {}
      @EXEC = {}

      @EXEC1 = { "target" => { "bash" => 0 } }

      @EXEC2 = { "target" => { "bash" => 1 } }

      TESTSUITE_INIT([@READ, @WRITE, @EXEC], nil)

      Yast.import "SambaTrustDom"

      DUMP("------------------------------------------------------------")
      TEST(lambda { SambaTrustDom.Establish("domain", "password") }, [
        @READ,
        @WRITE,
        @EXEC1
      ], nil)
      TEST(lambda { SambaTrustDom.Establish("domain", "password") }, [
        @READ,
        @WRITE,
        @EXEC2
      ], nil)
      DUMP("------------------------------------------------------------")
      TEST(lambda { SambaTrustDom.Establish("domain", "password\"\"abc") }, [
        @READ,
        @WRITE,
        @EXEC1
      ], nil)
      TEST(lambda { SambaTrustDom.Establish("domain", "password\"\"abc") }, [
        @READ,
        @WRITE,
        @EXEC2
      ], nil)
      DUMP("------------------------------------------------------------")
      TEST(lambda { SambaTrustDom.Establish("domain", "pas''sword\"\"'\"abc") }, [
        @READ,
        @WRITE,
        @EXEC1
      ], nil)
      TEST(lambda { SambaTrustDom.Establish("domain", "pas''sword\"\"'\"abc") }, [
        @READ,
        @WRITE,
        @EXEC2
      ], nil)
      DUMP("------------------------------------------------------------")

      nil
    end
  end
end

Yast::SambaTrustDomClient.new.main
