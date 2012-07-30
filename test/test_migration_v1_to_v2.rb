require 'helper'

class TestMigrationV1ToV2 < Test::Unit::TestCase
  context "GenericModel" do
    setup do
    end

    should "read both document types" do
      assert v1 = TestDocument.find('v1_doc')
      assert v2 = TestDocument.find('v2_doc')
      assert_equal 'this is v1 data', v1.message
      assert_equal 'this is v2 data', v2.message
    end

    should "write in v2" do
      document = TestDocument.new
      document.message = 'here is some new data'
      document.save
      same_document = TestDocument.find(document.key)
      assert_equal document.message, same_document.message
    end

    should "write in v2 raw confirmation" do
      document = TestDocument.new
      document.message = 'here is some new data'
      document.save
      expected_v2_data = '{"version":"0.0.2","iv":"ABYLnUHWE/fIwE2gKYC6hg==\n","data":"XcjjKHW6HWGMMHfRAg92eVtCOWb4epj1yi73o9bTFYdXGVmPSvVVBruuU0cL\n3iUWkhHvxh32P1wMI5nzKqgPsQ==\n"}'
      raw_data = `curl -s -XGET http://#{Ripple.config[:host]}:#{Ripple.config[:http_port]}/buckets/#{TestDocument.bucket_name}/keys/#{document.key}`
      assert_equal expected_v2_data, raw_data
    end
  end
end
