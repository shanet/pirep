require 'test_helper'

class ExternalCommandRunnerTest < ActiveSupport::TestCase
  test 'runs command' do
    streamed = ''

    status, output = ExternalCommandRunner.execute('ls') do |line|
      streamed += line
    end

    assert status.success?, 'Command not successful'
    assert output.present?, 'Output not populated'
    assert_equal streamed, output, 'Returned and streamed output differ'
  end

  test 'handles failed command' do
    status, output = ExternalCommandRunner.execute('ls', 42, print_failure: false)

    assert_not status.success?, 'Command not successful'
    assert output.present?, 'Output not populated'
  end
end
