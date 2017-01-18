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
        @subject = headers['Subject'].force_encoding('UTF-8')
        @from = EmailContact.from_string(@headers['From'].force_encoding('UTF-8'))
        @to = EmailContact.from_string(@headers['To'].force_encoding('UTF-8'))
    end


    def to_s
      "From: #{@from}\nTo: #{@to}\nSubject: #{@subject}\n\n#{@part&.to_s&.force_encoding('UTF-8')}"
    end

    def html_view(folder_name)
        Dir.mkdir(folder_name) unless File.exists?(folder_name)
        @part.html_view(folder_name)
    end
end
