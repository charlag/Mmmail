require './lib/parser'
require './lib/contact'
require './lib/parts'

class Email
    attr_reader :id
    attr_reader :headers
    attr_reader :subject, :from, :to, :part

    def initialize(id, string)
        @id = id
        @headers, @part = RFC822Parser.parse_message(string)
        @subject = headers['Subject']
        @from = EmailContact.new(@headers['From'])
        @to = EmailContact.new(@headers['To'])
    end


    def to_s
        "From: #{@from}\nTo: #{@to}\nSubject: #{@subject}\n\n#{@part}"
    end

    def html_view(folder_name)
        Dir.mkdir(folder_name) unless File.exists?(folder_name)
        @part.html_view(folder_name)
    end
end
