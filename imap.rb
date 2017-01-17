require 'net/imap'
require 'base64'
require 'nkf'

require './parser'

imap = Net::IMAP.new('imap.gmail.com', {port: 993, ssl: true})
key = File.read('gmail_key')
imap.login('shholylol@gmail.com', key)
# Net::IMAP::debug = true

class Email

    attr_reader :headers
    attr_reader :subject, :from, :to, :part

    def initialize(string)
        raw_headers, raw_body = parse_message(string)
        # puts "HEADERS", headers
        @headers = decode_headers(raw_headers)
        # @subject = parse_header(string[/Subject:\s(.*)\r/, 1])
        @subject = headers['Subject']
        from_string = string[/From:\s(.*)\r/, 1]
        @from = EmailContact.new(from_string)
        to_string = string[/To:\s(.*)\r/, 1]
        @to = EmailContact.new(to_string)
        body_start = string.index(/Content\-Type:\s(.*)$/)
        body = string[body_start..-1]
        @part = Email.parse_part(body)
    end


    def to_s
        "From: #{@from}\nTo: #{@to}\nSubject: #{@subject}\n\n#{@part}"
    end

    def html_view(folder_name)
        Dir.mkdir(folder_name) unless File.exists?(folder_name)
        @part.html_view(folder_name)
    end

    def self.parse_part(string)
        header, rest = string.split("\r\n\r\n", 2)
        type = header[/Content\-Type:\s(:?[^;\s]+)/, 1]
        case type
        when 'text/plain'
            part = TextPart.new(string)
        when 'text/html'
            part = HtmlPart.new(string)
        when /multipart\/related*/
            part = Multipart.new(string)
        when /multipart\/alternative*/
            part = MultipartAlternative.new(string)
        when /image\/*/
            part = ImagePart.new(string)
        end
        return part
    end

    def decode_headers(headers)
        return Hash[headers.map { |k, v| [k, decode_header(v)] } ]
        # return headers.map { |k, v| { k => decode_header(v) } }
    end

    def decode_header(str)
        parts = str.split(/\r\n/)
        decoded = parts.map do |part|
            if part.strip().start_with?("=?")
                chunks = part.strip().split("?")[1...-1] # drop =? and ?=
                charset = chunks[0]
                encoding = chunks[1].upcase
                data = chunks[2]
                if encoding == 'B'
                    # puts "decoding data, original: #{str}"
                    result = Base64.decode64(data)
                elsif encoding == 'Q'
                    result = data.unpack("M").first.gsub('_',' ')
                end
                result
            else
                part
            end
        end
        puts decoded.select { |p| !p.empty? }.to_s
        return decoded.select { |p| !p.empty? }.join()
    end
end

class EmailContact
    attr_reader :address, :name

    def initialize(string)
        email_in_braces = string[/<(.*?)>/m, 1]
        if email_in_braces != nil
            @address = email_in_braces
            @name = string.partition('<').first.strip
        else
            @address = string
        end
    end

    def to_s
        unless @name.nil?
            "#{@name} <#{@address}>"
        else
            @address
        end
    end
end

class Part
    @content

    def html_view(folder_name)
    end
end

class Multipart < Part
    attr_reader :parts

    def initialize(string)
        header, content = string.split("\r\n\r\n", 2)
        boundary = header[/boundary=(.*)$/, 1]
        @parts = content
            .chomp("--#{boundary}--\r\n")
            .split("--#{boundary}")
            .drop(1)
            .map { |raw_part| Email.parse_part(raw_part) }
    end

    def to_s
        @parts.map { |part| part.to_s }.join("\n")
    end

    def html_view(folder_name)
        @parts.each { |part| part.html_view(folder_name) }
    end
end

class MultipartAlternative < Multipart
    attr_reader :content

    def initialize(string)
        super(string)

        html_part = @parts.select {|part| part.instance_of? HtmlPart }.first
        unless html_part.nil?
            @content = html_part
        else
            @content = parts.first
        end
    end

    def to_s
        @parts.select{|part| part.instance_of? TextPart }.first.to_s
    end

    def html_view(folder_name)
        @content.html_view(folder_name)
    end
end

class TextPart < Part
    attr_reader :text

    def initialize(string)
        header, rest = string.split("\r\n\r\n", 2)
        # @text = rest
        charset = header[/charset=([^;\s]+)/, 1]
        encoding = header[/Content\-Transfer\-Encoding:\s(:?[^;\s]+)/, 1]
        case encoding
        when 'quoted-printable'
            decoded = rest.unpack('M').first
        when 'base64'
            decoded = rest.unpack('m').first
        end
        @text = decoded
    end

    def to_s
        @text
    end

    def html_view(folder_name)
        File.open(folder_name + '/page.html', 'w') { |file|
            file.write(@text)
        }
    end
end

class HtmlPart < TextPart

    def initialize(string)
        super(string)
    end
end

class ImagePart < Part
    attr_reader :data, :name, :cid

    def initialize(string)
        header, rest = string.split("\r\n\r\n", 2)
        @name = header[/name=([^;\s]+)/, 1]
        @cid = header[/Content-ID:\s([^;\s]+)/, 1][1..-2]
        @data = Base64.decode64(rest)
    end

    def to_s
        return "[Image]"
    end

    def html_view(folder_name)
        puts folder_name
        puts cid
        File.open(folder_name + '/' + @cid, 'w') do |file|
            file.write(@data)
        end
    end
end

def list_messages(imap, inbox)
    imap.select('Inbox')
    msgs = imap.search('ALL')
    msgs.map do |msg_id|
        raw_msg = imap.fetch(msg_id, 'RFC822').first.attr['RFC822']
        email = Email.new(raw_msg)
        puts email.subject
        puts '   ---   '
    end
end

list_messages(imap, 'Inbox')

# imap.select('Inbox')
# msgs = imap.search('ALL')
# raw_msg = imap.fetch(msgs.first, 'RFC822').first.attr['RFC822']
# puts raw_msg, '========================='
# headers, body = parse_message(raw_msg)
# puts headers['Subject: ']

# Shoes.app height: 450, width: 650 do
#     background white
#     msgs = list_messages(imap, 'Inbox')
#     stack do
#         msgs.each do |msg|
#             stack margin: 10 do
#                 para strong(msg.subject)
#                 para msg.from
#                 stack { line 0, 0, 200, 0, stroke: grey }
#             end
#         end
#     end
# end
