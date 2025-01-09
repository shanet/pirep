require 'open3'

class ExternalCommandRunner
  def self.execute(*command, print_failure: Rails.env.test?)
    command = normalize(*command)
    Rails.logger.info("Running command: #{command}")

    stdout_stderr, status = Open3.capture2e(*command)

    unless status.success?
      Rails.logger.error("Failed to run command: #{command.join(' ')}")

      # Print to stdout for tests so it's more obvious what the failure was. Otherwise, the caller can determine whether to print the output or not
      print_failure ? puts(stdout_stderr) : Rails.logger.error(stdout_stderr) # rubocop:disable Rails/Output
    end

    return status, stdout_stderr
  end

  def self.normalize(*command)
    return command.map(&:to_s)
  end
end
