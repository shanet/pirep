class Search < ApplicationRecord
  TABLE_LAST = 'searches_last'
  TABLE_CURRENT = table_name
  TABLE_NEXT = 'searches_next'

  # Models must be present in this list to be included for indexing. It is expected that they include the `Searchable` concern as well.
  SEARCH_MODELS = [Airport, Users::User]

  belongs_to :searchable, polymorphic: true

  def self.reindex!
    search_records = []

    # Collect indexing statements from all searchable models
    SEARCH_MODELS.each do |model|
      search_records << model.search_index
    end

    statements = [
      # Drop and create a new temporary search table by copying the structure of the existing one
      "DROP TABLE IF EXISTS #{TABLE_NEXT}",
      "CREATE TABLE #{TABLE_NEXT} (LIKE #{TABLE_CURRENT} INCLUDING DEFAULTS INCLUDING CONSTRAINTS INCLUDING INDEXES)",

      # Insert the search records for all models (note that `UNION ALL` won't check for duplicates here)
      "INSERT INTO #{TABLE_NEXT} (searchable_id, searchable_type, term_vector, term, coordinates) #{search_records.join("\nUNION ALL\n")}",

      # Replace the current searches table with the new one
      "ALTER TABLE #{TABLE_CURRENT} RENAME TO #{TABLE_LAST}",
      "ALTER TABLE #{TABLE_NEXT} RENAME TO #{TABLE_CURRENT}",
    ]

    transaction do
      statements.each do |statement|
        connection.execute(statement)
      end
    end

    # We don't need the old table anymore
    connection.execute("DROP TABLE IF EXISTS #{TABLE_LAST}")
  end

  def self.query(query, models=nil, coordinates=nil, wildcard: false)
    # Normalize casing, escape special characters that will cause syntax errors in the query, and truncate queries that are ridiculously long
    query = query.downcase.gsub("'", "''").truncate(100)

    [':', '(', ')', '<', '>'].each do |character|
      query = query.gsub(character, "\\#{character}")
    end

    # Add a suffix wildcard to the query if requested to allow for partial matches on words
    query = query.split.map {|term| wildcard ? "#{term}:*" : term}.join(' & ')

    # Only for airports: Rank the results by proximity to the coordinates if given any. This uses the `<@>` operator to calculate the distance
    # from the airport's coordinates to the given coordinates with Postgres' earthdistance extension. This assumes the Earth is a perfect sphere
    # which is close enough for our purposes here. This distance is then multiplied by the result's rank such that further away airports have a
    # higher rank and thus show lower in the results.
    #
    # Likewise, when doing the ranking we want to prioritize results for airport codes over airport nodes. The weights are set such that the
    # A and B weights will have higher ranking nearly always.
    coordinates_weight = (coordinates ? "* (point(#{coordinates[:latitude]}, #{coordinates[:longitude]}) <@> #{table_name}.coordinates)" : '')
    rank_column = "ts_rank('{1, .9, .1, 0}', term_vector, '#{query}') #{coordinates_weight} AS rank"

    # If we're given multiple models to search return search records directly. If we're only given one particular model then we can return that model's records
    # This allows to return an ActiveRecord Relation object if needed for further querying or by passing an array with multiple models for display in a mixed
    # global search results page or simply as a way to get the underlying search records for a given search term.
    search_query = if models.is_a? Array
                     select("#{table_name}.*", rank_column).where(searchable_type: models.map(&:name))
                   else
                     models.select("#{models.table_name}.*", rank_column).joins("INNER JOIN #{table_name} ON #{table_name}.searchable_id = #{models.table_name}.id")
                   end

    return search_query.where(sanitize_sql_for_conditions(["term_vector @@ to_tsquery('simple', ?)", query])).order(:rank)
  end
end
