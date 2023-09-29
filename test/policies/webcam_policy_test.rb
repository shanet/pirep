require 'policy_test'

class WebcamPolicyTest < PolicyTest
  setup do
    @webcam = create(:webcam)
  end

  test 'create' do
    assert_allows_all @webcam, :create, allow_disabled: false

    Rails.configuration.read_only.enable!
    assert_denies_all @webcam, :create
  ensure
    Rails.configuration.read_only.disable!
  end
end
