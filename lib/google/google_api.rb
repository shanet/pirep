require 'exceptions'

module GoogleApi
  def self.client
    return (Rails.application.credentials.google_api_key ? Service.new : Stub.new)
  end

  class Service
    API_HOST = 'https://maps.googleapis.com/maps/api/place'

    def place_photos(query, latitude, longitude)
      response = Faraday.get('%s/findplacefromtext/json' % API_HOST, {
        key: Rails.application.credentials.google_api_key,
        input: query,
        inputtype: :textquery,
        locationbias: 'circle:1500@%s,%s' % [latitude, longitude],
        fields: :place_id,
      })

      raise Exceptions::GooglePhotosQueryFailed unless response.success?

      results = JSON.parse(response.body)['candidates']
      return [] if results.empty?

      response = Faraday.get('%s/details/json' % API_HOST, {
        key: Rails.application.credentials.google_api_key,
        place_id: results.first['place_id'],
        fields: :photo,
      })

      raise Exceptions::GooglePhotosQueryFailed unless response.success?

      result = JSON.parse(response.body)['result']
      return [] unless result['photos']

      return result['photos'].reduce([]) do |photos, photo|
        response = Faraday.get('%s/photo' % API_HOST, {
          key: Rails.application.credentials.google_api_key,
          photoreference: photo['photo_reference'],
          maxwidth: 1000, # px
        })

        raise Exceptions::GooglePhotosQueryFailed unless response.status == 302

        photos << {url: response.headers[:location], attribution: photo['html_attribution']&.first}
      end
    rescue => error
      Sentry.capture_exception(error)
      return []
    end
  end

  class Stub
    def place_photos(*)
      return [
        {url: 'https://example.com/image1.jpg', attribution: 'John Doe'},
        {url: 'https://example.com/image2.jpg', attribution: 'Jane Doe'},
      ]
    end
  end
end
