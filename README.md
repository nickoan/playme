# playme
a simple ruby tcp server with reactor and thread pool

still in design, not finish yet!

basic sample :

```ruby
  
app = proc do |request|
  if request['Url'] == '/'
    str = 'this is me'
    [200, {'Content-Type' => 'text/html;charset=utf-8'}, str]
  else
    [500, {'Content-Type' => 'text/html;charset=utf-8'}, 'hello world']
  end

end

server = PlayMe::Base.new(app)
server.run!
```
