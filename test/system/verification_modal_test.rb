require 'application_system_test_case'

class VerificationModalTest < ApplicationSystemTestCase
  setup do
    Rails.configuration.verify_users_on_create = false
    @airport = create(:airport)
  end

  teardown do
    Rails.configuration.verify_users_on_create = true
  end

  test 'verifies user on form submission' do
    visit airport_path(@airport)

    click_link_or_button 'Add Webcam'
    fill_in 'webcam_url', with: 'https://example.com'
    find('input[type="submit"][value="Add Webcam"]').click

    # Ensure that the verification modal exists and is set to require verification
    assert_selector '#verification-modal[data-verification-required="true"].show'

    # Submit the modal
    within('#verification-modal') do
      click_link_or_button 'Submit'
    end

    # Verification should not be required anymore after submitting it on the next page
    assert_no_selector '#verification-modal', visible: false

    assert_equal 'https://example.com', find('#webcams .webcam-link').text, 'Form not submitted after verification modal submitted'
  end

  test 'verifies user on delete link click' do
    create(:tag, name: :food, airport: @airport)
    create(:tag, name: :camping, airport: @airport)
    visit airport_path(@airport)

    # Remove a tag
    find('.tag-square.add').click
    find('.tag-square[data-tag-name="food"] a.delete').click

    # The verification modal should be shown
    assert_selector '#verification-modal[data-verification-required="true"].show'

    # Submit the modal
    within('#verification-modal') do
      click_link_or_button 'Submit'
    end

    # Verification should not be required anymore after submitting it on the next page
    assert_selector '#verification-modal[data-verification-required="false"]', visible: false

    # And the tag should be gone now tii
    assert_no_selector '.tag-square[data-tag-name="food"]'

    # Removing another tag should now not require verification
    find('.tag-square[data-tag-name="camping"] a.delete').click
    assert_no_selector '#verification-modal'

    # The tag should be gone
    assert_no_selector '.tag-square[data-tag-name="camping"]'
  end

  test 'verifes users on Ajax form' do
    create(:comment, airport: @airport)
    visit airport_path(@airport)

    click_link_or_button 'Helpful'

    within('#verification-modal') do
      click_link_or_button 'Submit'
    end

    assert_selector '.helpful-count'
  end

  test 'cancels modal' do
    visit airport_path(@airport)

    click_link_or_button 'Edit Airport Access'
    find('label[for="airport_landing_rights_private_"]').click
    click_link_or_button 'Update Airport Access'

    assert_selector '#verification-modal[data-verification-required="true"].show'

    within('#verification-modal') do
      click_link_or_button 'Cancel'
    end

    assert_no_selector '#verification-modal'

    # The form submit button should be re-enabled for another submission if the modal was previously cancelled
    click_link_or_button 'Update Airport Access'
    assert_selector '#verification-modal[data-verification-required="true"].show'

    # Dismiss it by clicking the backdrop this time
    find('.modal-backdrop').click(x: 0, y: 200)
    assert_no_selector '#verification-modal[data-verification-required="true"]'
  end

  test 'does not verify already verified unknown user' do
    Rails.configuration.verify_users_on_create = true
    visit airport_path(@airport)

    # Verification should not be necessary for a verified unknown user
    assert_no_selector '#verification-modal', visible: false
  end

  test 'does not verify known user' do
    sign_in create(:known)
    visit airport_path(@airport)

    # Verification should not be needed for a known user
    assert_no_selector '#verification-modal', visible: false
  end

  test 'verifies users without interaction' do
    visit airport_path(@airport)

    # Do nothing and the modal should become non-required after the non-interactive challenge calls its callback
    assert_selector '#verification-modal[data-verification-required="false"]', visible: false
  end
end
