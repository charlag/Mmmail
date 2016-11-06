require 'net/imap'
require 'base64'
require 'nkf'

imap = Net::IMAP.new('imap.gmail.com', {port: 993, ssl: true})
imap.login('shholylol@gmail.com', 'nlnevhzhxmiuybyd')
imap.examine('[Gmail]/All Mail')

class Email
    attr_reader :subject, :from, :to, :part

    def initialize(string)
        @subject = string[/Subject:\s(.*)\r/, 1]
        from_string = string[/From:\s(.*)\r/, 1]
        @from = EmailContact.new(from_string)
        to_string = string[/To:\s(.*)\r/, 1]
        @to = EmailContact.new(to_string)
        body_start = string.index(/Content\-Type:\s(.*)$/)
        body = string[body_start..-1]
        @part = Email.parse_part(body)
    end

    private

    def self.parse_part(string)
        header, rest = string.split("\r\n\r\n", 2)
        type = header[/Content\-Type:\s(:?[^;\s]+)/][14..-1]
        case type
        when 'text/plain'
            part = PlainTextPart.new(rest)
        when 'text/html'
            part = HtmlPart.new(rest)
        when 'multipart/alternative', 'multipart/related'
            boundary = header[/boundary=(.*)$/, 1]
            part = Multipart.new(rest, boundary)
        when /image\/*/
            puts 'matched image'
            part = ImagePart.new(rest)
        end
        return part
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
end

class Part
    @content
end

class Multipart < Part
    attr_reader :parts

    def initialize(content, boundary)
        @parts = content
            .chomp("--#{boundary}--\r\n")
            .split("--#{boundary}")
            .drop(1)
            .map { |raw_part| Email.parse_part(raw_part) }
    end
end

class PlainTextPart < Part
    attr_reader :text, :charset

    def initialize(string)
    end
end

class HtmlPart < Part
    attr_reader :html, :charset

    def initialize(string)
    end
end

class ImagePart < Part
    attr_reader :data, :name

    def initialize(string)
    end
end

imap.search(['UNSEEN']).each do |message_id|
    message = imap.fetch(message_id, 'RFC822')
        .first
        .attr['RFC822']

    email = Email.new(message)
    puts email.inspect
    puts
    break
end
