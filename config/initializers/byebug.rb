if Rails.env.development?
  require 'byebug/core'

  begin
    Byebug.start_server 'localhost', 2424
  rescue Errno::EADDRINUSE, Errno::EADDRNOTAVAIL
    Rails.logger.info('Byebug port in use')
  end
end
