# Message consists of the header and body
# They're separaed by a 'null line' (nothing before CRLF)
# As i understand it, it means occurene of the '\r\n\r\n'
# I can try to divide message using this in two parts
# Then I should parse all headers properly, not sure my approach width
# "Let's just find a subject using regex" will work well here
# While it's possible to write such a regex it feels weird
CRLF = "\r\n"

DEBUG = false

def dbg(str)
    puts str if DEBUG
end

def parse_message(str)
    raw_header, raw_message = str.split(CRLF + CRLF, 2)
    return parse_headers(raw_header) #, parse_message(str)
end


def parse_headers(str)
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
