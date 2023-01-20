module Devise
  class LoginFailureRedirect < Devise::FailureApp
    def http_auth_body
      super unless request.xhr?

      # If an ajax request return the errors as a JavaScript function that will display them on the form
      return ApplicationController.render partial: 'shared/ajax_errors', locals: {form_element_id: 'login-form', record: OpenStruct.new(errors: i18n_message)} # rubocop:disable Style/OpenStructUse
    end
  end
end
