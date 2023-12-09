require 'policy_test'

class WebcamPolicyTest < PolicyTest
  setup do
    @webcam = create(:webcam)
  end

  ['create', 'destroy'].each do |action|
    test action do
      assert_allows_all @webcam, action, allow_disabled: false

      Rails.configuration.read_only.enable!
      assert_denies_all @webcam, action
    ensure
      Rails.configuration.read_only.disable!
    end
  end
end
