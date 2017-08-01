
require 'core/http_status_code'


module PlayMe
  class Parser
    def initialize
      @@header_reg = /(.*?):\s(.*)/
      @@post_body = /(.*?)=\s?(.*)/
      @@eds = "\r\n"
    end

    def execute(buff)
      hash = Hash.new
      request_arr = buff.split(@@eds)

      http_desc = top_info(request_arr.shift)
      hash['Version'] = http_desc.pop
      hash['Url'] = http_desc.pop
      hash['Method'] = http_desc.pop

      request_arr.size.times do |idx|
        current = request_arr[idx]
        if @@header_reg.match(current)
          header = current.split(':', 2)
          hash[header[0]] = header[1].strip
          request_arr[idx] = nil
        else
          if @@post_body.match(current)
            param = current.split('=', 2)
            hash['params'][param[0]] = param[1].strip
            request_arr[idx] = nil
          end
          next
        end
      end
      request_arr.compact!
      body = request_arr[0]
      hash[:body] = body

      return hash
    end


    def concat_response(response)

      state_desc = HttpStatusCode[response[0]]
      str = "HTTP/1.1 #{response[0]} #{state_desc}#{@@eds}"
      response[1].each do |k, v|
        str << "#{k}: #{v}#{@@eds}"
      end
      body = response[2].to_s << @@eds
      str << @@eds << body
      #return [str, true] if response[1]['Connection'] == 'keep-alive'
      [str, false]
    end

    private

    def top_info(str)
      str.split
    end
  end
end

