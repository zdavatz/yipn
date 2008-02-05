#!/usr/bin/env ruby

require 'rubygems'
require 'drb'
require 'paypal'
require 'yipn/config'

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
		request.status = 412 # Precondition Failed
		request.server.log_error("zero length input")
		exit
	end
  request.status = 500

  config = YIPN.config
  src = $stdin.read(content_length)
  notify = Paypal::Notification.new(src)

  if notify.complete? && notify.acknowledge
    drb_uris = config.drb_uris
    target = drb_uris[notify.params['custom']]
    DRb::DRbObject.new(nil, target).ipn(notify)
    request.status = 200
  else
    request.status = 200
    raise "Failed to verify Paypal IPN"
  end

rescue StandardError => error
  recipients = YIPN.config.error_recipients
  unless(recipients.empty?)
    require 'pp'
    require 'rmail'
    require 'net/smtp'
    mpart = RMail::Message.new
    header = mpart.header
    header.to = recipients
    header.from = config.mail_from
    header.subject = "IPN Error: #{error.message}"
    header.date = Time.now
    header.add('Content-Type', 'text/plain', nil, 
               'charset' => config.mail_charset)
    mpart.body = sprintf "Error: %s - %s\n\nIPN:\n%s\n\nBacktrace:%s",
                         error.class, error.message, notify.pretty_inspect,
                         error.backtrace.join("\n")
    smtp = Net::SMTP.new(config.smtp_server)
    smtp.start {
      recipients.each { |recipient|
        smtp.sendmail(mpart.to_s, config.smtp_from, recipient)
      }
    }
  end
  request.server.log_error(error.class.to_s)
  request.server.log_error(error.message)
  request.server.log_error(error.backtrace.join("\n"))
ensure
  request.send_http_header
end
