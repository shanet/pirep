# See http://localhost:3000/rails/mailers to view the mailer previews
class DeviseMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    Devise::Mailer.confirmation_instructions(Users::User.first, Devise.friendly_token)
  end

  def reset_password_instructions
    Devise::Mailer.reset_password_instructions(Users::User.first, Devise.friendly_token)
  end

  def unlock_instructions
    Devise::Mailer.unlock_instructions(Users::User.first, Devise.friendly_token)
  end
end
