require 'minitest/autorun'
require 'phocus'
require 'jsonpath'

class TestJsonpath < MiniTest::Unit::TestCase
  def setup
    @object = example_object
    @object2 = example_object
  end

  def test_bracket_matching
    assert_raises(ArgumentError) { JsonPath.new('$.store.book[0') }
    assert_raises(ArgumentError) { JsonPath.new('$.store.book[0]]') }
    assert_equal [9], JsonPath.new('$.store.book[0].price').on(@object)
  end

  def test_lookup_direct_path
    assert_equal 7, JsonPath.new('$.store.*').on(@object).first['book'].size
  end

  def test_lookup_missing_element
    assert_equal [], JsonPath.new('$.store.book[99].price').on(@object)
  end

  def test_retrieve_all_authors
    assert_equal [
      @object['store']['book'][0]['author'],
      @object['store']['book'][1]['author'],
      @object['store']['book'][2]['author'],
      @object['store']['book'][3]['author'],
      @object['store']['book'][4]['author'],
      @object['store']['book'][5]['author'],
      @object['store']['book'][6]['author']
    ], JsonPath.new('$..author').on(@object)
  end

  def test_retrieve_all_prices
    assert_equal [
      @object['store']['bicycle']['price'],
      @object['store']['book'][0]['price'],
      @object['store']['book'][1]['price'],
      @object['store']['book'][2]['price'],
      @object['store']['book'][3]['price']
    ].sort, JsonPath.new('$..price').on(@object).sort
  end

  def test_recognize_array_splices
    assert_equal [@object['store']['book'][0], @object['store']['book'][1]], JsonPath.new('$..book[0:1:1]').on(@object)
    assert_equal [@object['store']['book'][1], @object['store']['book'][3], @object['store']['book'][5]], JsonPath.new('$..book[1::2]').on(@object)
    assert_equal [@object['store']['book'][0], @object['store']['book'][2], @object['store']['book'][4], @object['store']['book'][6]], JsonPath.new('$..book[::2]').on(@object)
    assert_equal [@object['store']['book'][0], @object['store']['book'][2]], JsonPath.new('$..book[:-5:2]').on(@object)
    assert_equal [@object['store']['book'][5], @object['store']['book'][6]], JsonPath.new('$..book[5::]').on(@object)
  end

  def test_recognize_array_comma
    assert_equal [@object['store']['book'][0], @object['store']['book'][1]], JsonPath.new('$..book[0,1]').on(@object)
    assert_equal [@object['store']['book'][2], @object['store']['book'][6]], JsonPath.new('$..book[2,-1::]').on(@object)
  end

  def test_recognize_filters
    assert_equal [@object['store']['book'][2], @object['store']['book'][3]], JsonPath.new("$..book[?(@['isbn'])]").on(@object)
    assert_equal [@object['store']['book'][0], @object['store']['book'][2]], JsonPath.new("$..book[?(@['price'] < 10)]").on(@object)
    assert_equal [@object['store']['book'][0], @object['store']['book'][2]], JsonPath.new("$..book[?(@['price'] == 9)]").on(@object)
    assert_equal [@object['store']['book'][3]], JsonPath.new("$..book[?(@['price'] > 20)]").on(@object)
  end

  def test_or_operator
    assert_equal [@object['store']['book'][1], @object['store']['book'][3]], JsonPath.new("$..book[?(@['price'] == 13 || @['price'] == 23)]").on(@object)
  end

  def test_and_operator
    assert_equal [], JsonPath.new("$..book[?(@['price'] == 13 && @['price'] == 23)]").on(@object)
  end

  def test_and_operator_with_more_results
    assert_equal [@object['store']['book'][1]], JsonPath.new("$..book[?(@['price'] < 23 && @['price'] > 9)]").on(@object)
  end

  def test_eval_with_floating_point_and_and
    assert_equal [@object['store']['book'][1]], JsonPath.new("$..book[?(@['price'] < 23.0 && @['price'] > 9.0)]").on(@object)
  end

  def test_eval_with_floating_point
    assert_equal [@object['store']['book'][1]], JsonPath.new("$..book[?(@['price'] == 13.0)]").on(@object)
  end

  def test_paths_with_underscores
    assert_equal [@object['store']['bicycle']['catalogue_number']], JsonPath.new('$.store.bicycle.catalogue_number').on(@object)
  end

  def test_path_with_hyphens
    assert_equal [@object['store']['bicycle']['single-speed']], JsonPath.new('$.store.bicycle.single-speed').on(@object)
  end

  def test_path_with_colon
    assert_equal [@object['store']['bicycle']['make:model']], JsonPath.new('$.store.bicycle.make:model').on(@object)
  end

  def test_paths_with_numbers
    assert_equal [@object['store']['bicycle']['2seater']], JsonPath.new('$.store.bicycle.2seater').on(@object)
  end

  def test_recognize_array_with_evald_index
    assert_equal [@object['store']['book'][2]], JsonPath.new('$..book[(@.length-5)]').on(@object)
  end

  def test_use_first
    assert_equal @object['store']['book'][2], JsonPath.new('$..book[(@.length-5)]').first(@object)
  end

  def test_counting
    assert_equal 57, JsonPath.new('$..*').on(@object).to_a.size
  end

  def test_space_in_path
    assert_equal ['e'], JsonPath.new("$.'c d'").on('a' => 'a', 'b' => 'b', 'c d' => 'e')
  end

  def test_class_method
    assert_equal JsonPath.new('$..author').on(@object), JsonPath.on(@object, '$..author')
  end

  def test_join
    assert_equal JsonPath.new('$.store.book..author').on(@object), JsonPath.new('$.store').join('book..author').on(@object)
  end

  def test_gsub
    @object2['store']['bicycle']['price'] += 10
    @object2['store']['book'][0]['price'] += 10
    @object2['store']['book'][1]['price'] += 10
    @object2['store']['book'][2]['price'] += 10
    @object2['store']['book'][3]['price'] += 10
    assert_equal @object2, JsonPath.for(@object).gsub('$..price') { |p| p + 10 }.to_hash
  end

  def test_gsub!
    JsonPath.for(@object).gsub!('$..price') { |p| p + 10 }
    assert_equal 30, @object['store']['bicycle']['price']
    assert_equal 19, @object['store']['book'][0]['price']
    assert_equal 23, @object['store']['book'][1]['price']
    assert_equal 19, @object['store']['book'][2]['price']
    assert_equal 33, @object['store']['book'][3]['price']
  end

  def test_weird_gsub!
    h = { 'hi' => 'there' }
    JsonPath.for(@object).gsub!('$.*') { |_| h }
    assert_equal h, @object
  end

  def test_gsub_to_false!
    h = { 'hi' => 'there' }
    h2 = { 'hi' => false }
    assert_equal h2, JsonPath.for(h).gsub!('$.hi') { |_| false }.to_hash
  end

  def test_where_selector
    JsonPath.for(@object).gsub!('$..book.price[?(@ > 20)]') { |p| p + 10 }
  end

  def test_compact
    h = { 'hi' => 'there', 'you' => nil }
    JsonPath.for(h).compact!
    assert_equal({ 'hi' => 'there' }, h)
  end

  def test_delete
    h = { 'hi' => 'there', 'you' => nil }
    JsonPath.for(h).delete!('*.hi')
    assert_equal({ 'you' => nil }, h)
  end

  def test_delete_for_array
    before = JsonPath.on(@object, '$..store.book[1]')
    JsonPath.for(@object).delete!('$..store.book[0]')
    after = JsonPath.on(@object, '$..store.book[0]')
    assert_equal(after, before, 'Before is the second element. After should have been equal to the next element after delete.')
  end

  def test_at_sign_in_json_element
    data =
      { '@colors' =>
      [{ '@r' => 255, '@g' => 0, '@b' => 0 },
       { '@r' => 0, '@g' => 255, '@b' => 0 },
       { '@r' => 0, '@g' => 0, '@b' => 255 }] }

    assert_equal [255, 0, 0], JsonPath.on(data, '$..@r')
  end

  def test_wildcard
    assert_equal @object['store']['book'].collect { |e| e['price'] }.compact, JsonPath.on(@object, '$..book[*].price')
  end

  def test_wildcard_on_intermediary_element
    assert_equal [1], JsonPath.on({ 'a' => { 'b' => { 'c' => 1 } } }, '$.a..c')
  end

  def test_wildcard_on_intermediary_element_v2
    assert_equal [1], JsonPath.on({ 'a' => { 'b' => { 'd' => { 'c' => 1 } } } }, '$.a..c')
  end

  def test_wildcard_on_intermediary_element_v3
    assert_equal [1], JsonPath.on({ 'a' => { 'b' => { 'd' => { 'c' => 1 } } } }, '$.a.*..c')
  end

  def test_wildcard_on_intermediary_element_v4
    assert_equal [1], JsonPath.on({ 'a' => { 'b' => { 'd' => { 'c' => 1 } } } }, '$.a.*..c')
  end

  def test_wildcard_on_intermediary_element_v5
    assert_equal [1], JsonPath.on({ 'a' => { 'b' => { 'c' => 1 } } }, '$.a.*.c')
  end

  def test_wildcard_on_intermediary_element_v6
    assert_equal ['red'], JsonPath.new('$.store.*.color').on(@object)
  end

  def test_wildcard_empty_array
    object = @object.merge('bicycle' => { 'tire' => [] })
    assert_equal [], JsonPath.on(object, '$..bicycle.tire[*]')
  end

  def test_support_filter_by_array_childnode_value
    assert_equal [@object['store']['book'][3]], JsonPath.new('$..book[?(@.price > 20)]').on(@object)
  end

  def test_support_filter_by_childnode_value_with_inconsistent_children
    @object['store']['book'][0] = 'string_instead_of_object'
    assert_equal [@object['store']['book'][3]], JsonPath.new('$..book[?(@.price > 20)]').on(@object)
  end

  def test_support_filter_by_childnode_value_and_select_child_key
    assert_equal [23], JsonPath.new('$..book[?(@.price > 20)].price').on(@object)
  end

  def test_support_filter_by_childnode_value_over_childnode_and_select_child_key
    assert_equal ['Osennie Vizity'], JsonPath.new('$..book[?(@.written.year == 1996)].title').on(@object)
  end

  def test_support_filter_by_object_childnode_value
    data = {
      'data' => {
        'type' => 'users',
        'id' => '123'
      }
    }
    assert_equal [{ 'type' => 'users', 'id' => '123' }], JsonPath.new("$.data[?(@.type == 'users')]").on(data)
    assert_equal [], JsonPath.new("$.data[?(@.type == 'admins')]").on(data)
  end

  def test_support_at_sign_in_member_names
    assert_equal [@object['store']['@id']], JsonPath.new("$.store.@id").on(@object)
  end

  def test_support_dollar_sign_in_member_names
    assert_equal [@object['store']['$meta-data']],
      JsonPath.new("$.store.$meta-data").on(@object)
  end

  def test_support_underscore_in_member_names
    assert_equal [@object['store']['_links']],
      JsonPath.new("$.store._links").on(@object)
  end

  def test_dig_return_string
    assert_equal ['asdf'], JsonPath.new("$.store.book..tags[?(@ == 'asdf')]").on(@object)
    assert_equal [], JsonPath.new("$.store.book..tags[?(@ == 'not_asdf')]").on(@object)
  end

  def test_slash_in_value
    data = {
      'data' => {
        'type' => 'mps/awesome'
      }
    }
    assert_equal [{ 'type' => 'mps/awesome' }], JsonPath.new("$.data[?(@.type == \"mps/awesome\")]").on(data)
  end

  def test_floating_point_with_precision_marker
    data = {
      'data' => {
        'type' => 0.00001
      }
    }
    assert_equal [{"type"=>0.00001}], JsonPath.new("$.data[?(@.type == 0.00001)]").on(data)
  end

  def test_digits_only_string
    data = {
      'foo' => {
        'type' => 'users',
        'id' => '123'
      }
    }
    assert_equal([{"type"=>"users", "id"=>"123"}], JsonPath.new("$.foo[?(@.id == '123')]").on(data))
  end

  def test_at_in_filter
    jsonld = {
      "mentions" => [
         {
            "name" => "Delimara Powerplant",
            "identifier" => "krzana://took/powerstation/Delimara Powerplant",
            "@type" => "Place",
            "geo" => {
               "latitude" => 35.83020073454,
               "longitude" => 14.55602645874
            }
         }
      ]
   }
   assert_equal(['Place'], JsonPath.new("$..mentions[?(@['@type'] == 'Place')].@type").on(jsonld))
  end

  def test_dollar_in_filter
    jsonld = {
      "mentions" => [
         {
            "name" => "Delimara Powerplant",
            "identifier" => "krzana://took/powerstation/Delimara Powerplant",
            "$type" => "Place",
            "geo" => {
               "latitude" => 35.83020073454,
               "longitude" => 14.55602645874
            }
         }
      ]
   }
   assert_equal(['Place'], JsonPath.new("$..mentions[?(@['$type'] == 'Place')].$type").on(jsonld))
  end

  def test_at_in_value
    jsonld = {
      "mentions" =>
         {
            "name" => "Delimara Powerplant",
            "identifier" => "krzana://took/powerstation/Delimara Powerplant",
            "type" => "@Place",
            "geo" => {
               "latitude" => 35.83020073454,
               "longitude" => 14.55602645874
            }
         }
   }
   assert_equal(['@Place'], JsonPath.new("$..mentions.type[?(@ == '@Place')]").on(jsonld))
  end  

  def example_object
    { 'store' => {
      'book' => [
        { 'category' => 'reference',
          'author' => 'Nigel Rees',
          'title' => 'Sayings of the Century',
          'price' => 9,
          'tags' => ['asdf', 'asdf2']},
        { 'category' => 'fiction',
          'author' => 'Evelyn Waugh',
          'title' => 'Sword of Honour',
          'price' => 13 },
        { 'category' => 'fiction',
          'author' => 'Herman Melville',
          'title' => 'Moby Dick',
          'isbn' => '0-553-21311-3',
          'price' => 9 },
        { 'category' => 'fiction',
          'author' => 'J. R. R. Tolkien',
          'title' => 'The Lord of the Rings',
          'isbn' => '0-395-19395-8',
          'price' => 23 },
        { 'category' => 'russian_fiction',
          'author' => 'Lukyanenko',
          'title' => 'Imperatory Illuziy',
          'written' => {
            'year' => 1995
          } },
        { 'category' => 'russian_fiction',
          'author' => 'Lukyanenko',
          'title' => 'Osennie Vizity',
          'written' => {
            'year' => 1996
          } },
        { 'category' => 'russian_fiction',
          'author' => 'Lukyanenko',
          'title' => 'Ne vremya dlya drakonov',
          'written' => {
            'year' => 1997
          } }
      ],
      'bicycle' => {
        'color' => 'red',
        'price' => 20,
        'catalogue_number' => 123_45,
        'single-speed' => 'no',
        '2seater' => 'yes',
        'make:model' => 'Zippy Sweetwheeler'
      },
      "@id" => "http://example.org/store/42",
      "$meta-data" => "whatevs",
      "_links" => { "self" => {} }
    } }
  end
end
