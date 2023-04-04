require 'exceptions'

class AirportPhotosCacherJob < ApplicationJob
  def perform(airport, photos)
    ActiveRecord::Base.transaction do
      # Remove all of the existing photos before uploading new ones
      airport.external_photos.purge

      attachments = []

      Dir.mktmpdir do |tmp_directory|
        photos.each_with_index do |photo, index|
          response = fetch_photo(photo[:url])

          # I guess it's safe to assume that these are all jpegs?
          path = File.join(tmp_directory, "#{airport.code.downcase}_external_#{index}.jpg")
          File.binwrite(path, response)

          attachments << {io: File.open(path), filename: File.basename(path), content_type: 'image/jpeg'}
        end
      end

      airport.external_photos_updated_at = Time.zone.now
      airport.external_photos_enqueued_at = nil
      airport.external_photos.attach(attachments)
      airport.save!
    end
  end

  def self.enqueued_for_airport?(airport)
    return GoodJob::Job.where('serialized_params @> ?', {job_class: self.class.name.to_s}.to_json)
      .where('serialized_params @> ?', {arguments: [{_aj_globalid: "gid://pirep/Airport/#{airport.id}"}]}.to_json)
      .where(finished_at: nil).any?
  end

private

  def fetch_photo(url)
    # Stub this in test since we can't get any actual photos
    return fetch_photo_stub if Rails.env.test?

    response = Faraday.get(url)
    raise Exceptions::GooglePhotosQueryFailed unless response.success?

    return response.body
  end

  def fetch_photo_stub
    return Rails.root.join('test/fixtures/files/image.png').read
  end
end
