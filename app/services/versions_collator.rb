class VersionsCollator
  PERIOD = 10.minutes

  def initialize(record)
    @record = record
  end

  # Combine versions created in a short time period into one version to make for a more comphrensive and useful history display
  def collate!
    # Only consider versions from the previous day so we're not attempting to collate possibly an entire lengthy history
    cursor = @record.versions.where('created_at > ?', 1.day.ago).each
    return if cursor.size == 0 # rubocop:disable Style/ZeroLengthPredicate

    version = cursor.next
    batch = [(version.event == 'update' ? version : nil)].compact

    loop do
      version = cursor.next

      # Don't collate creation/deletion events
      next unless version.event == 'update'

      # If the version was created by the same user and is within the collation period as the previous version group it together in that batch
      if version.created_at - (batch.last&.created_at || 0) < PERIOD && version.whodunnit == batch.last&.whodunnit
        batch << version
      else
        process_batch!(batch)
        batch = [version]
      end
    end

    process_batch!(batch)
  end

private

  def process_batch!(batch)
    return if batch.size == 1

    collated_changes = {}

    batch.each do |version|
      version.object_changes&.each do |key, value|
        # If the version already has an edit in the given column overwite its value with the value from the subsequent edit
        if collated_changes[key]
          collated_changes[key][1] = value[1]
        else
          collated_changes[key] = value
        end
      end
    end

    # Write the collated changes to the first version in the batch and discard the rest
    ActiveRecord::Base.transaction do
      batch.each_with_index do |version, index|
        if index == 0
          version.update!(object_changes: collated_changes)
        else
          # Reassign any actions that reference the current version to the first version in the batch
          Action.where(version: version).update!(version: batch.first)
          version.destroy!
        end
      end
    end
  end
end
