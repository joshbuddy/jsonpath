require "rubygems"
require 'lib/jsonpath.rb'
require 'json'
describe "JsonPath" do

  object = { "store"=> {
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
        "price"=> 19.95
      }
    }
  }
  json = JsonPath.wrap(object)

  it "should lookup a direct path" do
    json.path('$.store.*').to_a.first['book'].size.should == 4
  end

  it "should retrieve all authors" do
    json.path('$..author').to_a.should == [
      object['store']['book'][0]['author'],
      object['store']['book'][1]['author'],
      object['store']['book'][2]['author'],
      object['store']['book'][3]['author']
    ]
  end
  
  it "should retrieve all prices" do
    json.path('$..price').to_a.should == [
      object['store']['bicycle']['price'],
      object['store']['book'][0]['price'],
      object['store']['book'][1]['price'],
      object['store']['book'][2]['price'],
      object['store']['book'][3]['price']
    ]
  end
  
  it "should recognize all types of array splices" do
    json.path('$..book[0:1:1]').to_a.should == [object['store']['book'][0], object['store']['book'][1]]
    json.path('$..book[1::2]').to_a.should == [object['store']['book'][1], object['store']['book'][3]]
    json.path('$..book[::2]').to_a.should == [object['store']['book'][0], object['store']['book'][2]]
    json.path('$..book[:-2:2]').to_a.should == [object['store']['book'][0], object['store']['book'][2]]
    json.path('$..book[2::]').to_a.should == [object['store']['book'][2], object['store']['book'][3]]
  end
  
  it "should recognize array comma syntax" do
    json.path('$..book[0,1]').to_a.should == [object['store']['book'][0], object['store']['book'][1]]
    json.path('$..book[2,-1::]').to_a.should == [object['store']['book'][2], object['store']['book'][3]]
  end
  
  it "should support filters" do
    json.path("$..book[?(@['isbn'])]").to_a.should == [object['store']['book'][2], object['store']['book'][3]]
    json.path("$..book[?(@['price'] < 10)]").to_a.should == [object['store']['book'][0], object['store']['book'][2]]
  end
  
  it "should support eval'd array indicies" do
    json.path('$..book[(@.length-2)]').to_a.should == [object['store']['book'][2]]
  end
  
  it "should correct retrieve the right number of all nodes" do
    json.path('$..*').to_a.size.should == 28
  end
  
end
