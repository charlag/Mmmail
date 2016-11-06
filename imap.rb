require 'net/imap'
require 'base64'
require 'nkf'

imap = Net::IMAP.new('imap.gmail.com', {port: 993, ssl: true})
key = File.read('gmail_key')
imap.login('shholylol@gmail.com', key)
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


    def to_s
        "From: #{@from}\nTo: #{@to}\nSubject: #{@subject}\n\n#{@part}"
    end

    def html_view(folder_name)
        Dir.mkdir(folder_name) unless File.exists?(folder_name)
        @part.html_view(folder_name)
    end

    private

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

imap.search(['UNSEEN']).each do |message_id|
    message = imap.fetch(message_id, 'RFC822')
        .first
        .attr['RFC822']

    email = Email.new(message)
    puts email
    # File.open('.tmppage.html', 'w') do |file|
    #     file.write(email.part.to_s)
    # end
    email.html_view(Dir.pwd + '/tmppage')
    system('open tmppage/page.html')
    break
end
