# This patch fixes an issue with RAILS_ENV being set to "development" in test when running the `tast:all` task.
# There's a fix for it already merged but it's not part of Rails 7.0.4. It can likely be removed with Rails 7.1.
#
# See https://github.com/rails/rails/pull/45439

require 'rails/commands/test/test_command'

module Rails
  module Command
    class TestCommand < Base
      raise('Remove me in Rails 7.1') if Gem.loaded_specs['rails'].version.to_s >= '7.1'

      desc 'test:all', 'Runs all tests, including system tests', hide: true
      def all(*)
        args.prepend('test/**/*_test.rb')
        perform
      end
    end
  end
end
