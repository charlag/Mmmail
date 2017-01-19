require './lib/parts'

# Message consists of the header and body
# They're separaed by a 'null line' (nothing before CRLF)
# As i understand it, it means occurene of the '\r\n\r\n'
# I can try to divide message using this in two parts
# Then I should parse all headers properly, not sure my approach width
# "Let's just find a subject using regex" will work well here
# While it's possible to write such a regex it feels weird
CRLF = "\r\n"

DEBUG = false

class RFC822Parser
    def self.parse_message(str)
        raw_headers, _ = str.split(CRLF + CRLF, 2)
        headers = decode_headers(parse_headers(raw_headers))
        return headers, parse_part(str)
    end

    def self.parse_headers(str)
        offset = 0
        headers = {}

        loop do
            maybe_title_position = str.index(': ', offset)
            dbg "DEBUG0 maybe_title_position: #{maybe_title_position}"
            break if maybe_title_position.nil?
            title_position = maybe_title_position

            title = str[offset..title_position - 1]
            offset = title_position + 2
            dbg "DEBUG title: #{title}, offset now: #{offset}"
            loop do
                # puts "DEBUF crlf_index str: #{str[offset, 40]}, offset: #{offset}"
                crlf_index = str.index(CRLF, offset)
                dbg "DEBUG2 crlf_index: #{crlf_index}"
                if crlf_index.nil?
                    dbg "DEBUG3 crlf is nil, title value: #{str[title_position..-1]}"
                    headers[title] = str[title_position + 2..-1]
                    break
                end

                offset = crlf_index + 2
                next_char = str[offset] # CRLF is two symbols
                dbg "DEBUG4 offset now: #{offset}, next_char: #{next_char}"
                if next_char != ' ' && next_char != "\t"
                    dbg "DEBUG5 next_char is not space it's code: #{next_char.ord}, title value: #{str[title_position..crlf_index-1]}, from: #{title_position} to #{crlf_index}"
                    headers[title] = str[title_position + 2..crlf_index-1]
                    break
                end
                dbg "DEBUG6 nex_char is space, next iteration"
            end
        end

        return headers
    end

    def self.decode_headers(headers)
        return Hash[headers.map { |k, v| [k, decode_header(v)] } ]
    end

    def self.decode_header(str)
        parts = str.split(/\r\n/)
        decoded = parts.map do |part|
            if part.strip().start_with?("=?")
                chunks = part.strip().split("?")[1...-1] # drop =? and ?=
                charset = chunks[0]
                encoding = chunks[1].upcase
                data = chunks[2]
                if encoding == 'B'
                    result = Base64.decode64(data)
                elsif encoding == 'Q'
                    result = data.unpack("M").first.gsub('_',' ')
                end
                result
            else
                part
            end
        end
        return decoded.select { |p| !p.empty? }.join()
    end

    def self.parse_part(string)
        header, rest = string.split("\r\n\r\n", 2)
        type = header[/Content\-Type:\s(:?[^;\s]+)/, 1]
        puts "type: #{type}, header: #{header[0..400]} \n\n rest: #{rest[0..400]}"
        puts "\n ==== ==== ----------------------- ==== ==== \n"
        case type
        when 'text/plain'
            part = TextPart.new(string)
        when 'text/html'
            part = HtmlPart.new(string)
        when /multipart\/related*/
            part = Multipart.new(string)
        when /multipart\/mixed*/
            part = Multipart.new(string)
        when /multipart\/alternative*/
            part = MultipartAlternative.new(string)
        when /application\/octet-stream*/
          part = FilePart.new(string)
        when /image\/*/
            part = ImagePart.new(string)
        end
        return part
    end

    private_class_method def self.dbg(str)
        puts str if DEBUG
    end
end
