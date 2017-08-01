
module PlayMe

  HttpStatusCode = Hash.new


  # status 200
  HttpStatusCode[200] = 'OK'
  HttpStatusCode[201] = 'Created'

  # status 300
  HttpStatusCode[301] = 'Moved Permanently'
  HttpStatusCode[302] = 'Move temporarily'
  HttpStatusCode[303] = 'See Other'
  HttpStatusCode[304] = 'Not Modified'
  HttpStatusCode[305] = 'Use Proxy'

  # status 400
  HttpStatusCode[400] = 'Bad Request'
  HttpStatusCode[401] = 'Unauthorized'
  HttpStatusCode[402] = 'Payment Required'
  HttpStatusCode[403] = 'Forbidden'
  HttpStatusCode[404] = 'Not Found'


  # status 500
  HttpStatusCode[500] = 'Internal Server Error'
  HttpStatusCode[501] = 'Not Implemented'
  HttpStatusCode[502] = 'Bad Gateway'
  HttpStatusCode[503] = 'Service Unavailable'
end