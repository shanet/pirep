module Searchable
  extend ActiveSupport::Concern

  included do
    class_attribute :search_terms

    has_many :searches, as: :searchable, dependent: :destroy

    after_create :search_reindex!
    after_save :search_reindex!, if: :should_reindex?
  end

  def search_reindex!
    transaction do
      self.class.search_terms.map do |term|
        statement = <<~SQL.squish
          INSERT INTO searches (
            searchable_id, searchable_type, term_vector, term, coordinates
          )
          SELECT
            id :: uuid,
            '#{self.class.name}',
            #{self.class.term_to_tsvector(term)},
            '#{term[:column]}',
            #{instance_of?(Airport) ? 'coordinates' : 'NULL::point'}
          FROM
            #{self.class.table_name}
          WHERE
            id = '#{id}'
            AND #{term[:column]} IS NOT NULL AND #{term[:column]} != ''
          ON CONFLICT (searchable_id, searchable_type, term) DO UPDATE SET
            term_vector = excluded.term_vector, coordinates = excluded.coordinates
        SQL

        self.class.connection.execute(statement)
      end
    end
  end

  def should_reindex?
    return search_terms.any? do |term|
      send("saved_change_to_#{term[:column]}?")
    end
  end

  module ClassMethods
    def searchable(term)
      self.search_terms ||= []
      self.search_terms << term
    end

    def search_index
      return self.search_terms.map do |term|
        <<~SQL.squish
          SELECT
            id::uuid,
            '#{name}',
            #{term_to_tsvector(term)},
            '#{term[:column]}',
            #{self == Airport ? 'coordinates' : 'NULL::point'}
          FROM #{table_name}
          WHERE #{term[:column]} IS NOT NULL AND #{term[:column]} != ''
        SQL
      end
    end

    def term_to_tsvector(term)
      # Use "simple" language here to avoid mangaling names since these are all proper nouns and specific terms
      term_vector = "to_tsvector('simple', #{term[:column]})"

      if term[:weight]
        # Allow for conditional weighting
        if term[:weight].is_a? Array
          term_vector = "CASE WHEN #{term[:weight][0]} THEN setweight(#{term_vector}, '#{term[:weight][1]}') ELSE setweight(#{term_vector}, '#{term[:weight][2]}') END"
        else
          term_vector = "setweight(#{term_vector}, '#{term[:weight]}')"
        end
      end

      return term_vector
    end
  end
end
