class VersionsCollatorJob < ApplicationJob
  def perform(record)
    VersionsCollator.new(record).collate!
  end
end
