#!/usr/bin/env ruby
# Stub::Apache -- yipn -- 29.01.2008 -- hwyss@ywesee.com

require 'drb'

module Apache
  def Apache.request
    DRb::DRbObject.new(nil, ARGV[0])
  end
end
