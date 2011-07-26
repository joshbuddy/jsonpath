class TestJsonpath < MiniTest::Unit::TestCase

  def setup
    @object = example_object
    @object2 = example_object
  end

  def test_lookup_direct_path
    assert_equal 4, JsonPath.new('$.store.*').on(@object).first['book'].size
  end

  def test_retrieve_all_authors
    assert_equal [
      @object['store']['book'][0]['author'],
      @object['store']['book'][1]['author'],
      @object['store']['book'][2]['author'],
      @object['store']['book'][3]['author']
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
    assert_equal [@object['store']['book'][1], @object['store']['book'][3]], JsonPath.new('$..book[1::2]').on(@object)
    assert_equal [@object['store']['book'][0], @object['store']['book'][2]], JsonPath.new('$..book[::2]').on(@object)
    assert_equal [@object['store']['book'][0], @object['store']['book'][2]], JsonPath.new('$..book[:-2:2]').on(@object)
    assert_equal [@object['store']['book'][2], @object['store']['book'][3]], JsonPath.new('$..book[2::]').on(@object)
  end

  def test_recognize_array_comma
    assert_equal [@object['store']['book'][0], @object['store']['book'][1]], JsonPath.new('$..book[0,1]').on(@object)
    assert_equal [@object['store']['book'][2], @object['store']['book'][3]], JsonPath.new('$..book[2,-1::]').on(@object)
  end

  def test_recognize_filters
    assert_equal [@object['store']['book'][2], @object['store']['book'][3]], JsonPath.new("$..book[?(@['isbn'])]").on(@object)
    assert_equal [@object['store']['book'][0], @object['store']['book'][2]], JsonPath.new("$..book[?(@['price'] < 10)]").on(@object)
    assert_equal [@object['store']['book'][0], @object['store']['book'][2]], JsonPath.new("$..book[?(@['price'] == 9)]").on(@object)
    assert_equal [@object['store']['book'][3]], JsonPath.new("$..book[?(@['price'] > 20)]").on(@object)
    assert_equal [@object['store']['book'][2], @object['store']['book'][3]], JsonPath.new("$..book[?(@.isbn)]").on(@object)
  end

  def test_no_eval
    assert_equal [], JsonPath.new('$..book[(@.length-2)]', :allow_eval => false).on(@object)
  end

  def test_paths_with_underscores
    assert_equal [@object['store']['bicycle']['catalogue_number']], JsonPath.new('$.store.bicycle.catalogue_number').on(@object)
  end

  def test_paths_with_numbers
    assert_equal [@object['store']['bicycle']['2seater']], JsonPath.new('$.store.bicycle.2seater').on(@object)
  end

  def test_recognize_array_with_evald_index
    assert_equal [@object['store']['book'][2]], JsonPath.new('$..book[(@.length-2)]').on(@object)
  end

  def test_use_first
    assert_equal @object['store']['book'][2], JsonPath.new('$..book[(@.length-2)]').first(@object)
  end

  def test_counting
    assert_equal 30, JsonPath.new('$..*').on(@object).to_a.size
  end

  def test_space_in_path
    assert_equal ['e'], JsonPath.new("$.'c d'").on({"a" => "a","b" => "b", "c d" => "e"})
  end

  def test_class_method
    assert_equal JsonPath.new('$..author').on(@object), JsonPath.on(@object, '$..author')
  end

  def test_gsub
    @object2['store']['bicycle']['price'] += 10
    @object2['store']['book'][0]['price'] += 10
    @object2['store']['book'][1]['price'] += 10
    @object2['store']['book'][2]['price'] += 10
    @object2['store']['book'][3]['price'] += 10
    assert_equal @object2, JsonPath.for(@object).gsub('$..price') { |p| p + 10 }
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
    h = {'hi' => 'there'}
    JsonPath.for(@object).gsub!('$.*') { |n| h }
    assert_equal h, @object
  end

  def example_object
    { "store"=> {
      "book" => [
        { "category"=> "reference",
          "author"=> "Nigel Rees",
          "title"=> "Sayings of the Century",
          "price"=> 9
        },
        { "category"=> "fiction",
          "author"=> "Evelyn Waugh",
          "title"=> "Sword of Honour",
          "price"=> 13
        },
        { "category"=> "fiction",
          "author"=> "Herman Melville",
          "title"=> "Moby Dick",
          "isbn"=> "0-553-21311-3",
          "price"=> 9
        },
        { "category"=> "fiction",
          "author"=> "J. R. R. Tolkien",
          "title"=> "The Lord of the Rings",
          "isbn"=> "0-395-19395-8",
          "price"=> 23
        }
      ],
    "bicycle"=> {
      "color"=> "red",
      "price"=> 20,
      "catalogue_number" => 12345,
      "2seater" => "yes"}
    } }
  end

end
