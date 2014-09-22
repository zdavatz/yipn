#!/usr/bin/env ruby
# config -- yipn -- 05.02.2008 -- hwyss@ywesee.com

require 'rclconf'

module YIPN
  dir = File.expand_path('..', ENV['DOCUMENT_ROOT'] || './doc')
  default_dir = File.expand_path('etc', dir)
  default_config_files = [
    File.join(default_dir, 'yipn.yml'),
    '/etc/yipn/yipn.yml',
  ]
  defaults = {
    'config'           => default_config_files,
    'drb_uris'         => {},
    'error_recipients' => [],
    'mail_charset'     => 'utf8',
    'mail_from'        => '"IPN (PayPal -> ywesee)" <ipn@ywesee.com>',
    'smtp_from'        => 'ipn@ywesee.com',
    'smtp_server'      => 'localhost',
  }
  config = RCLConf::RCLConf.new(ARGV, defaults)
  config.load(config.config, :trusted => true)

  @config = config

  class << self
    attr_accessor :config
  end
  
end
