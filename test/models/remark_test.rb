require 'test_helper'

class RemarkTest < ActiveSupport::TestCase
  test 'downcase and capitalizes human readable remarks' do
    remark = create(:remark, text: 'ESTABD PRIOR TO 15 MAY 1959')
    assert_equal 'Estabd prior to 15 may 1959', remark.to_human_readable, 'Remark not human readable'
  end
end
