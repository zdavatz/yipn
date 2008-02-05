#!/usr/bin/env ruby
# TestIpn -- 29.01.2008 -- hwyss@ywesee.com

$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'fileutils'
require 'flexmock'
require 'drb'
require 'paypal'
require 'net/smtp'

module YIPN
  class TestIpn < Test::Unit::TestCase
    class Request
      include DRb::DRbUndumped
      attr_accessor :status, :request_method, :body
      def initialize
        @body = ''
      end
      def connection
        self
      end
      def headers_in
        {
          'Content-Length' => @body.size
        }
      end
      def server
        self
      end
      def log_notice *args
      end
      def log_error *args
      end
      def remote_ip
        "127.0.0.1"
      end
      def send_http_header
      end
    end
    class Client
      attr_reader :notification
      def ipn(notification)
        @notification = notification
      end
    end
    include FlexMock::TestCase
    def setup
      @stub = File.expand_path('stub/apache.rb', File.dirname(__FILE__))
      @script = File.expand_path('../doc/index.rbx', File.dirname(__FILE__))
      @config = File.expand_path('etc/yipn.yml', File.dirname(__FILE__))
      @defaults = {
        "drb_uris" => [],
        "error_recipients" => [], # since the tested script runs in a 
                                  # separate process, don't send any mail
      }
      ENV['DOCUMENT_ROOT'] = File.expand_path('doc', File.dirname(__FILE__))
      @request = Request.new
      @service = DRb.start_service('druby://localhost:0', @request)
      @lib = File.expand_path('../lib', File.dirname(__FILE__))
      @body = <<-EOS
payment_date=05%3A17%3A56+Jan+29%2C+2008+PST&txn_type=web_accept&last_name=Schlumpf&residence_country=CH&item_name=unlimited+access&payment_gross=&mc_currency=EUR&business=hannes.wyss%40gmail.com&payment_type=instant&verify_sign=AQU0e5vuZCvSg-XJploSa.sGUDlpAoVH4GXMGblXrYaf583nKz5FE4Wp&payer_status=verified&test_ipn=1&tax=0.00&payer_email=schlumpfine.schlumpf%40schlumpfhausen.org&txn_id=4R001344FM5198836&quantity=1&receiver_email=hannes.wyss%40gmail.com&first_name=Schlumpfine&invoice=929a63c9f90923d0b13d4ce5c83468f6&payer_id=BZH9BSGVSTQR2&receiver_id=P2YNHYXAJERLL&item_number=929a63c9f90923d0b13d4ce5c83468f6&payment_status=Completed&payment_fee=&mc_fee=16.53&shipping=0.00&mc_gross=476.00&custom=de.oddb.org&charset=windows-1252&notify_version=2.4
      EOS
      super
    end
    def run_script method = 'POST', body = ''
      @request.request_method = method
      @request.body = body
      command = "ruby -I#@lib -r#@stub #@script #{@service.uri}"
      IO.popen(command, 'w+') { |io| 
        io.write body
        io.close_write
        io.read }
    end
    def test_get
      run_script 'GET'
      assert_equal(0, $?)
      assert_equal(405, @request.status)
    end
    def test_post__empty
      run_script 'POST'
      assert_equal(0, $?)
      assert_equal(412, @request.status)
    end
    def test_post__no_drb_connection
      smtp = flexmock('smtp')
      client_de = Client.new
      drb_de = DRb.start_service('druby://localhost:0', client_de)
      client_ch = Client.new
      drb_ch = DRb.start_service('druby://localhost:0', client_ch)
      FileUtils.mkdir_p File.dirname(@config)
      File.open(@config, 'w') { |fh|
        fh.puts( @defaults.update('drb_uris' => { 
          'de.oddb.org' => drb_de.uri, 
          'ch.oddb.org' => drb_ch.uri }).to_yaml )
      }
      drb_de.stop_service
      run_script 'POST', @body
      assert_equal(0, $?)
      assert_equal(500, @request.status)
      assert_nil client_de.notification
      assert_nil client_ch.notification
    end
    def test_post__success
      client_de = Client.new
      drb_de = DRb.start_service('druby://localhost:0', client_de)
      client_ch = Client.new
      drb_ch = DRb.start_service('druby://localhost:0', client_ch)
      FileUtils.mkdir_p File.dirname(@config)
      File.open(@config, 'w') { |fh|
        fh.puts( @defaults.update('drb_uris' => { 
          'de.oddb.org' => drb_de.uri, 
          'ch.oddb.org' => drb_ch.uri }).to_yaml )
      }
      run_script 'POST', @body
      assert_equal(0, $?)
      assert_equal(200, @request.status)
      assert_instance_of Paypal::Notification, client_de.notification
      assert_nil client_ch.notification
    end
    def test_post__incomplete
      body = <<-EOS
payment_date=05%3A17%3A56+Jan+29%2C+2008+PST&txn_type=web_accept&last_name=Schlumpf&residence_country=CH&item_name=unlimited+access&payment_gross=&mc_currency=EUR&business=hannes.wyss%40gmail.com&payment_type=instant&verify_sign=AQU0e5vuZCvSg-XJploSa.sGUDlpAoVH4GXMGblXrYaf583nKz5FE4Wp&payer_status=verified&test_ipn=1&tax=0.00&payer_email=schlumpfine.schlumpf%40schlumpfhausen.org&txn_id=4R001344FM5198836&quantity=1&receiver_email=hannes.wyss%40gmail.com&first_name=Schlumpfine&invoice=929a63c9f90923d0b13d4ce5c83468f6&payer_id=BZH9BSGVSTQR2&receiver_id=P2YNHYXAJERLL&item_number=929a63c9f90923d0b13d4ce5c83468f6&payment_status=Invalid&payment_fee=&mc_fee=16.53&shipping=0.00&mc_gross=476.00&custom=de.oddb.org&charset=windows-1252&notify_version=2.4
      EOS
      client_de = Client.new
      drb_de = DRb.start_service('druby://localhost:0', client_de)
      client_ch = Client.new
      drb_ch = DRb.start_service('druby://localhost:0', client_ch)
      FileUtils.mkdir_p File.dirname(@config)
      File.open(@config, 'w') { |fh|
        fh.puts( @defaults.update('drb_uris' => { 
          'de.oddb.org' => drb_de.uri, 
          'ch.oddb.org' => drb_ch.uri }).to_yaml )
      }
      run_script 'POST', body
      assert_equal(0, $?)
      assert_equal(200, @request.status)
      assert_nil client_de.notification
      assert_nil client_ch.notification
    end
  end
end
