#!/usr/bin/env ruby

require 'drb'
require 'active_support/core_ext/class/attribute_accessors'
require 'paypal'
require 'pp'
require 'mail'
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

  if notify.complete?
    drb_uris = config.drb_uris
    target = drb_uris[notify.params['custom']] || drb_uris['ch.oddb.org']
    DRb::DRbObject.new(nil, target).ipn(notify)
    request.status = 200
    unless(notify.acknowledge)
      raise "Failed to verify Paypal IPN - Access granted!"
    end
  else
    request.status = 200
    raise "Failed to verify Paypal IPN"
  end

rescue StandardError => error
  recipients = YIPN.config.error_recipients
  unless(recipients.empty?)
    Mail.defaults do
      delivery_method :smtp, {
        :address        => config.smtp_server,
        :port           => config.smtp_port,
        :domain         => config.smtp_domain,
        :user_name      => config.smtp_user,
        :password       => config.smtp_pass,
      }
    end
    mail = Mail.new
    mail.from    config.mail_from
    mail.to      recipients
    mail.subject "IPN Error: #{error.message}"
    mail.body    sprintf "Error: %s - %s\n\nIPN:\n%s\n\nBacktrace:%s",
                          error.class, error.message, notify.pretty_inspect,
                          error.backtrace.join("\n")
    if ENV['MINITEST']
      Mail.defaults do delivery_method :test end
      Mail::TestMailer.deliveries.clear
      mail.delivery_method :test
    end  
    mail.deliver
    $stderr.puts "Delivered #{Mail::TestMailer.deliveries.size} e-mail(s) to #{mail.to}"
  end
  request.server.log_error(error.class.to_s)
  request.server.log_error(error.message)
  request.server.log_error(error.backtrace.join("\n"))
ensure
  request.send_http_header
end
