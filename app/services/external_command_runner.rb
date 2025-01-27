require 'open3'

class ExternalCommandRunner
  def self.execute(*command, print_failure: Rails.env.test?)
    command = normalize(*command)
    Rails.logger.info("Running command: #{command}")

    output = ''
    status = nil

    Open3.popen2e(*command) do |_stdin, stdout_stderr, wait_thread|
      stdout_stderr.each do |line|
        yield line if block_given?
        output += line
      end

      status = wait_thread.value
    end

    unless status.success?
      Rails.logger.error("Failed to run command: #{command.join(' ')}")

      # Print to stdout for tests so it's more obvious what the failure was. Otherwise, the caller can determine whether to print the output or not
      print_failure ? puts(output) : Rails.logger.error(output) # rubocop:disable Rails/Output
    end

    return status, output
  end

  def self.normalize(*command)
    return command.map(&:to_s)
  end
end
