# The read only model is a singleton that holds a simple boolean controlling if the site is in read only mode or not
Rails.configuration.after_initialize do
  Rails.configuration.read_only = ReadOnly::Loader.new
end
