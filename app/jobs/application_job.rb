class ApplicationJob < ActiveJob::Base
  # Drop anything that fails to deserialize (possibly because the underlying record was deleted)
  discard_on ActiveJob::DeserializationError
end
