require 'securerandom'

def main
  # Don't run the seeds if there is already an admin user
  return puts 'Admin account already exists, aborting seeds' if Users::Admin.any? # rubocop:disable Rails/Output

  default_email = 'admin@example.com'
  default_password = SecureRandom.hex

  Users::Admin.create!(email: default_email, password: default_password, confirmed_at: Time.zone.now)

  puts "Admin user created.\n\tEmail: #{default_email}\n\tPassword: #{default_password}\nSeeds finished" # rubocop:disable Rails/Output
end

main
