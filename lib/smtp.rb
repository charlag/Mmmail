require 'net/smtp'
require 'time'

SMTPMessage = Struct.new(:from, :to, :subject, :body, :date, :attachments) do

    def to_s
        marker = "AUNIQUEMARKER"
        header_part = %{From: #{from.name} <#{from.address}>
To: #{to.name} <#{to.address}>
Subject: #{subject}
Date: #{date.rfc2822}
Message-Id: <#{date.to_time.to_i.to_s + from.address}>
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=#{marker}
}

        text_part = %{
Content-Type: text/plain
Content-Transfer-Encoding:8bit

#{body}
}
        # dirty hack just to save an array before it blows up for no reason
        attachs = attachments.dup
        attachs ||= []

        puts "attachs: #{attachs.to_s}"
        formatted_attachments = attachs.map do |attach|
            file_content = File.read(attach)
            encoded_content = [file_content].pack 'm' # base64
            %{
Content-Type: application/octet-stream; name=\"#{attach}\"
Content-Transfer-Encoding:base64
Content-Disposition: attachment; filename="#{attach}"

#{encoded_content}
}
        end
        all_parts = [header_part, text_part] + formatted_attachments
        return all_parts.join("--#{marker}") + "--#{marker}--"
    end
end

class SMTPClient
    def self.send_message(message)
        smtp = Net::SMTP.new 'smtp.gmail.com', 587
        smtp.set_debug_output $stdout
        smtp.enable_starttls
        key = File.read('gmail_key')
        smtp.start('gmail.com') do
            smtp.auth_plain 'shholylol@gmail.com', key
            smtp.send_message message.to_s, message.from.address, message.to.address
        end
    end
end
