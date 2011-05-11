require 'spec_helper'

describe "JsonPath" do

  before(:each) do
    @object = { "store"=> {
        "book" => [
          { "category"=> "reference",
            "author"=> "Nigel Rees",
            "title"=> "Sayings of the Century",
            "price"=> 8.95
          },
          { "category"=> "fiction",
            "author"=> "Evelyn Waugh",
            "title"=> "Sword of Honour",
            "price"=> 12.99
          },
          { "category"=> "fiction",
            "author"=> "Herman Melville",
            "title"=> "Moby Dick",
            "isbn"=> "0-553-21311-3",
            "price"=> 8.99
          },
          { "category"=> "fiction",
            "author"=> "J. R. R. Tolkien",
            "title"=> "The Lord of the Rings",
            "isbn"=> "0-395-19395-8",
            "price"=> 22.99
          }
        ],
        "bicycle"=> {
          "color"=> "red",
          "price"=> 19.95,
          "catalogue_number" => 12345,
        }
      }
    }
  end

  it "should lookup a direct path" do
    JsonPath.new('$.store.*').on(@object).to_a.first['book'].size.should == 4
  end

  it "should retrieve all authors" do
    JsonPath.new('$..author').on(@object).to_a.should == [
      @object['store']['book'][0]['author'],
      @object['store']['book'][1]['author'],
      @object['store']['book'][2]['author'],
      @object['store']['book'][3]['author']
    ]
  end

  it "should retrieve all prices" do
    JsonPath.new('$..price').on(@object).to_a.sort.should == [
      @object['store']['bicycle']['price'],
      @object['store']['book'][0]['price'],
      @object['store']['book'][1]['price'],
      @object['store']['book'][2]['price'],
      @object['store']['book'][3]['price']
    ].sort
  end

  it "should recognize all types of array splices" do
    JsonPath.new('$..book[0:1:1]').on(@object).to_a.should == [@object['store']['book'][0], @object['store']['book'][1]]
    JsonPath.new('$..book[1::2]').on(@object).to_a.should == [@object['store']['book'][1], @object['store']['book'][3]]
    JsonPath.new('$..book[::2]').on(@object).to_a.should == [@object['store']['book'][0], @object['store']['book'][2]]
    JsonPath.new('$..book[:-2:2]').on(@object).to_a.should == [@object['store']['book'][0], @object['store']['book'][2]]
    JsonPath.new('$..book[2::]').on(@object).to_a.should == [@object['store']['book'][2], @object['store']['book'][3]]
  end

  it "should recognize array comma syntax" do
    JsonPath.new('$..book[0,1]').on(@object).to_a.should == [@object['store']['book'][0], @object['store']['book'][1]]
    JsonPath.new('$..book[2,-1::]').on(@object).to_a.should == [@object['store']['book'][2], @object['store']['book'][3]]
  end

  it "should support filters" do
    JsonPath.new("$..book[?(@['isbn'])]").on(@object).to_a.should == [@object['store']['book'][2], @object['store']['book'][3]]
    JsonPath.new("$..book[?(@['price'] < 10)]").on(@object).to_a.should == [@object['store']['book'][0], @object['store']['book'][2]]
  end
  
  it "should recognize paths with underscores" do
    JsonPath.new('$.store.bicycle.catalogue_number').on(@object).to_a.should == [@object['store']['bicycle']['catalogue_number']]
  end

  it "should support eval'd array indicies" do
    JsonPath.new('$..book[(@.length-2)]').on(@object).to_a.should == [@object['store']['book'][2]]
  end

  it "should correct retrieve the right number of all nodes" do
    JsonPath.new('$..*').on(@object).to_a.size.should == 29
  end

  it "should deal with a space in the key name" do
    JsonPath.new("$.'c d'").on({"a" => "a","b" => "b", "c d" => "e"}).to_a.should == ['e']
  end

  it "should support a convenience class method" do
    JsonPath.on(@object, '$..author').to_a.should == JsonPath.new('$..author').on(@object).to_a
  end

end
