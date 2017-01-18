require 'net/imap'
require './lib/email'

class IMAPClient
    def initialize()
        @imap = Net::IMAP.new('imap.gmail.com', {port: 993, ssl: true})
        key = File.read('gmail_key')
        @imap.login('shholylol@gmail.com', key)
    end

    def get_messages()
        @imap.select('Inbox')
        msgs = @imap.search('ALL')
        msgs.map do |msg_id|
            raw_msg = @imap.fetch(msg_id, 'RFC822').first.attr['RFC822']
            # File.open(msg_id.to_s, 'w+') do |f|
            #   f.write(raw_msg)
            # end
            Email.new(msg_id, raw_msg)
        end
    end

    def delete_message(id)
        @imap.store(id, "+FLAGS", [:Deleted])
        @imap.expunge()
    end
end
