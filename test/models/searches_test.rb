require 'test_helper'

class SearchesTest < ActiveSupport::TestCase
  setup do
    @public_airport = create(:airport, code: 'PIT', name: 'Pittsburgh International', latitude: 10, longitude: 10)
    @private_airport = create(:airport, code: 'PA00', name: 'Pitts Field', facility_use: 'PR', latitude: 20, longitude: 20)
    @known_user = create(:known)
    @unknown_user = create(:unknown)

    Search.reindex!
  end

  test 'indexes records' do
    assert_equal 3, Search.where(searchable: @public_airport).count
    assert_equal 3, Search.where(searchable: @private_airport).count
    assert_equal 2, Search.where(searchable: @known_user).count
    assert_equal 3, Search.where(searchable: @unknown_user).count

    # Reindexing should result in no difference to the number of search records
    assert_difference('Search.count', 0) do
      Search.reindex!
    end
  end

  test 'indexes new record' do
    # Creating a new record should index it by default (the airports model has three search records in particular)
    assert_difference('Search.count', 3) do
      create(:airport)
    end
  end

  test 'reindexes single record' do
    # Reindexing a record should not change the total of number of search records
    search = @public_airport.searches.find_by(term: :name)

    assert_difference('Search.count', 0) do
      @public_airport.update!(name: 'Foobar Regional')
    end

    assert_not_equal search.term_vector, @public_airport.searches.find_by(term: :name).term_vector, 'Search term vector did not change on reindex'
  end

  test 'searches by public airports by code' do
    results = Search.query(@public_airport.code, [Airport], wildcard: true)

    assert_search_rank_ordering results
    assert_equal @public_airport, results.first.searchable, 'First result not ICAO code of public airport'
  end

  test 'searches by private airports by code' do
    results = Search.query(@private_airport.code, [Airport], wildcard: true)

    assert_search_rank_ordering results
    assert_equal @private_airport, results.first.searchable, 'First result not ICAO code of private airport'
  end

  test 'searches by public airports by name' do
    results = Search.query('pitt', [Airport], wildcard: true)

    assert_search_rank_ordering results
    assert_equal @public_airport, results.first.searchable, 'First result not name of public airport'
  end

  test 'searches by public airports by name with apostrophe' do
    airport = create(:airport, name: "O'Hare International")
    results = Search.query("O'hare", [Airport], wildcard: true)

    assert_search_rank_ordering results
    assert_equal airport, results.first.searchable, 'First result not name of public airport'
  end

  test 'searches by public airports by name with whitespace' do
    results = Search.query(@public_airport.name, [Airport], wildcard: true)

    assert_search_rank_ordering results
    assert_equal @public_airport, results.first.searchable, 'First result not name of public airport'
  end

  test 'searches by private airports by name' do
    results = Search.query(@private_airport.name, [Airport], wildcard: true)

    assert_search_rank_ordering results
    assert_equal @private_airport, results.first.searchable, 'First result not name of private airport'
  end

  test 'searches without wildcard' do
    results = Search.query(@public_airport.name[0..3], [Airport])
    assert results.empty?, 'No results without wildcard searching'
  end

  test 'searches by location for airports by code' do
    results = Search.query(@public_airport.code, [Airport], {latitude: @public_airport.latitude, longitude: @public_airport.longitude}, wildcard: true)

    assert_search_rank_ordering results
    assert_equal @public_airport, results.first.searchable, 'First result not ICAO code of public airport'
  end

  test 'searches by location for airports by name' do
    results = Search.query('Pitts', [Airport], {latitude: @private_airport.latitude, longitude: @private_airport.longitude}, wildcard: true)

    assert_search_rank_ordering results
    assert_equal @private_airport, results.first.searchable, 'First result not closer airport despite being private'
  end

  test 'searches by user email address' do
    results = Search.query(@known_user.email, [Users::User], wildcard: true)

    assert_search_rank_ordering results
    assert_equal @known_user, results.first.searchable, 'First result not known user'
  end

  test 'searches by user IP address' do
    results = Search.query(@unknown_user.ip_address, [Users::User], wildcard: true)

    assert_search_rank_ordering results
    assert_equal @unknown_user, results.first.searchable, 'First result not unknown user'
  end

  test 'search for single model type' do
    # Passing a model not in an array should return objects of that type rather than the underlying search records
    results = Search.query(@public_airport.code, Airport, wildcard: true)
    assert results.first.is_a?(Airport), 'Search results not returned as model type'
  end

  test 'searches for multiple model types' do
    airport = create(:airport, name: @known_user.name)
    results = Search.query(@known_user.name, [Airport, Users::User], wildcard: true)

    [airport, @known_user].each do |record|
      assert results.map(&:searchable).include?(record), 'Record not present in mixed type search results'
    end
  end

  test 'gets count of search results' do
    count = Search.query(@public_airport.code, Airport, wildcard: true).count(Airport.table_name)
    assert count.is_a?(Integer), 'Did not return integer for count of search results'
  end

  test 'handles queries with special characters' do
    assert Search.query('!@#$%^&*()_-=+|/\\{}[];:\'"`~.,<>?', Airport, wildcard: true).empty?, 'Did not handle search query with special characters'
  end

  test 'handles extremely long query' do
    assert_nothing_raised do
      Search.query('a ' * 1_000, Airport, wildcard: true)
    end
  end

private

  def assert_search_rank_ordering(results)
    assert_equal results.map(&:rank).sort, results.map(&:rank), 'Search results not ordered by rank'
  end
end
