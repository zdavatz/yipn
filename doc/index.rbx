#!/usr/bin/env ruby

require 'rubygems'
require 'drb'
require 'paypal'

request = Apache.request
begin
	connection = request.connection

	request.server.log_notice \
    "Received Request #{request.request_method} from #{connection.remote_ip}"
	if(request.request_method != 'POST')
		request.status = 405 # Method not allowed
		exit
	end
	content_length = request.headers_in['Content-Length'].to_i
	request.server.log_notice("content-length: #{content_length}")
	if(content_length <= 0)
		request.status = 500 # Server Error
		request.server.log_error("zero length input")
		exit
	end

  src = $stdin.read(content_length)
  notify = Paypal::Notification.new(src)

  if notify.complete?
    path = ENV['CLIENT_CONFIG'].dup
    path.untaint if /clients.yml$/.match path
    drb_uris = YAML.load File.read(path)
    request.server.log_notice drb_uris.inspect
    request.server.log_notice notify.params.inspect
    target = drb_uris[notify.params['custom']]
    DRb::DRbObject.new(nil, target).ipn(notify)
    notify.acknowledge
  else
    request.server.log_error("Failed to verify Paypal IPN")
  end
  request.status = 200

rescue StandardError => err
  request.server.log_error(err.class.to_s)
  request.server.log_error(err.message)
  request.server.log_error(err.backtrace.join("\n"))
  request.status = 500
ensure
  request.send_http_header
end
