require 'base64'
require 'nkf'
require './lib/parser'

class Part
    @content

    def html_view(folder_name)
    end
end

class Multipart < Part
    attr_reader :parts

    def initialize(string)
        header, content = string.split("\r\n\r\n", 2)
        puts "DEBUG: header, #{header}"
        boundary = header[/boundary=(.*)$/, 1]
        puts "DEBUG: Boundary: #{boundary}"
        raw_parts = content
            .chomp("--#{boundary}--\r\n")
            .split("--#{boundary}")
        ff = "--#{boundary}"
        @parts = content
            .chomp("--#{boundary}--\r\n")
            .split("--#{boundary}")
            .drop(1)
            .map { |raw_part| RFC822Parser.parse_part(raw_part) }
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
        raw_cid = header[/Content-ID:\s([^;\s]+)/, 1]
        @cid = raw_cid && raw_cid[1..-2]
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
