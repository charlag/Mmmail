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
      puts @headers['From']
      puts @headers['From'].force_encoding('UTF-8')
      puts @from.to_s
      puts @from.to_s&.force_encoding('UTF-8')
      "From: #{@from.to_s&.force_encoding('UTF-8')}\n" +
      "To: #{@to.to_s&.force_encoding('UTF-8')}\n" +
      "Subject: #{@subject}\n\n" +
      "#{@part&.to_s&.force_encoding('UTF-8')}"
    end

    def html_view(folder_name)
        Dir.mkdir(folder_name) unless File.exists?(folder_name)
        @part.html_view(folder_name)
    end
end
