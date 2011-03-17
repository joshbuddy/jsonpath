# Jsonpath

This is an implementation of http://goessner.net/articles/JsonPath/. 

## Usage

There is stand-alone usage through the binary `jsonpath`

    jsonpath [expression] (file|string)

    If you omit the second argument, it will read stdin, assuming one valid JSON object
    per line. Expression must be a valid jsonpath expression.

As well, you can include it as a library.

    object = JSON.parse(<<-HERE_DOC))
    {"store": 
      {"bicycle":
        {"price":19.95, "color":"red"},
        "book":[
          {"price":8.95, "category":"reference", "title":"Sayings of the Century", "author":"Nigel Rees"},
          {"price":12.99, "category":"fiction", "title":"Sword of Honour", "author":"Evelyn Waugh"},
          {"price":8.99, "category":"fiction", "isbn":"0-553-21311-3", "title":"Moby Dick", "author":"Herman Melville"},
          {"price":22.99, "category":"fiction", "isbn":"0-395-19395-8", "title":"The Lord of the Rings", "author":"J. R. R. Tolkien"}
        ]
      }
    }
    HERE_DOC

    JsonPath.new('$..price').on(object).to_a
    # => [19.95, 8.95, 12.99, 8.99, 22.99]
  
    JsonPath.new('$..author').on(object).to_a
    # => ["Nigel Rees", "Evelyn Waugh", "Herman Melville", "J. R. R. Tolkien"]
  
    JsonPath.new('$..book[::2]').on(object).to_a
    # => [{"price"=>8.95, "category"=>"reference", "author"=>"Nigel Rees", "title"=>"Sayings of the Century"}, {"price"=>8.99, "category"=>"fiction", "author"=>"Herman Melville", "title"=>"Moby Dick", "isbn"=>"0-553-21311-3"}]
