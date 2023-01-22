Rails.configuration.after_initialize do
  # The FAA data cycle model holds which data cycle is active for the various FAA products used on the site
  Rails.configuration.faa_data_cycle = FaaDataCycle::Loader.new

  # The read only model is a singleton that holds a simple boolean controlling if the site is in read only mode or not
  Rails.configuration.read_only = ReadOnly::Loader.new
end
