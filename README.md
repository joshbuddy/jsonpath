# Jsonpath

This is an implementation of http://goessner.net/articles/JsonPath/.

## Usage

There is stand-alone usage through the binary `jsonpath`

    jsonpath [expression] (file|string)

    If you omit the second argument, it will read stdin, assuming one valid JSON object
    per line. Expression must be a valid jsonpath expression.

As well, you can include it as a library.

~~~~~ {ruby}
    object = JSON.parse(<<-HERE_DOC)
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

    JsonPath.new('$..price').on(object)
    # => [19.95, 8.95, 12.99, 8.99, 22.99]

    JsonPath.on(object, '$..author')
    # => ["Nigel Rees", "Evelyn Waugh", "Herman Melville", "J. R. R. Tolkien"]

    JsonPath.new('$..book[::2]').on(object)
    # => [{"price"=>8.95, "category"=>"reference", "author"=>"Nigel Rees", "title"=>"Sayings of the Century"}, {"price"=>8.99, "category"=>"fiction", "author"=>"Herman Melville", "title"=>"Moby Dick", "isbn"=>"0-553-21311-3"}]

    JsonPath.new('$..color').first(object)
    # => "red"

    # Lazy enumeration - only needs to find the first two matches
    JsonPath.new('$..price').enum_on(object).each do |match|
      break price if price < 15.0
    end
    # => 8.95
~~~~~

You can optionally prevent eval from being called on sub-expressions by passing in :allow_eval => false to the constructor.

If you'd like to do substitution in a json object, do this:

~~~~~ {ruby}
    JsonPath.for({'test' => 'time'}).gsub('$..test') {|v| v << v}
~~~~~

The result will be

~~~~~ {ruby}
    {'test' => 'timetime'}
~~~~~
