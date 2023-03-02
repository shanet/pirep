# Adapted from https://github.com/rails/rails/issues/38161#issuecomment-826391646
module AttachmentOrganizable
  extend ActiveSupport::Concern

  class_methods do
    def has_many_attached_with(name, path:, &block) # rubocop:disable Naming/PredicateName
      has_many_attached(name, &block)

      define_method "#{name}=" do |attachable|
        action = super(attachable)

        action.blobs.each do |blob|
          # Skip already uploaded attachments
          next if blob.persisted?

          # Get the default key and prepend the specified path to it
          default_key = blob.class.generate_unique_secure_token
          extension = File.extname(blob.filename.to_s)
          blob.key = File.join(instance_exec(&path), default_key + extension)
        end

        return action
      end
    end
  end
end
