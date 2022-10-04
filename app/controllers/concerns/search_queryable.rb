module SearchQueryable
  extend ActiveSupport::Concern

  def preprocess_query
    query = params['query']

    # Chop off the `K` prefix from a full ICAO airport code since our database does not have these
    return (query.length == 4 ? query.upcase.gsub(/^K/, '') : query)
  end
end
