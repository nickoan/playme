# playme
a simple ruby tcp server with reactor and thread pool

still in design, not finish yet!

basic sample :

```ruby
  app = proc do |request|
    "HTTP/1.1 200 OK\r\n\r\nHello\r\n"
  end

  server = PlayMe::Base.new(app)
  server.run!
```
