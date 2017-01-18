require './lib/imap_client'

class EmailWindow < Shoes::Widget

  def initialize(email)
    stack margin: 10 do
        flow do
            reply = button "Reply"
            reply.click {|| open_reply(email) }
            delete = button "Delete"
            delete.click {|| delete(email) }
        end
        para email.to_s
        attachments email
    end
  end

  def attachments(email)
      if email.part.is_a? Multipart
          attachs = email.part.parts.select {|p| p.is_a? ImagePart}
          unless attachs.empty?
              flow height: 20 do
                  attachs.each do |a|
                      attach_btn = button a.name
                      attach_btn.click {|| open_attach(a) }
                  end
              end
          end
      end
  end

  def open_attach(attach)
    attach_path = File.expand_path(attach.filename, '~/Downloads')
    File.open(attach_path, 'wb') do |f|
      f.write(attach.data)
    end
    spawn("open #{attach_path}")
  end

  def open_reply(email)
    window do
      stack margin: 10 do
        para "Address"
        from = edit_line
        from.text = email.from
        para "Message"
        edit_box
        send = button "Send"
      end
    end
  end

  def delete(email)
    owner.client.delete_message(email.id)
    owner.refresh_messages()
    close
  end
end

Shoes.app height: 450, width: 650 , title: 'MMMail' do

  def client()
    @client
  end

  def open_email(email)
    window do |window|
      email_window email
    end
  end

  def refresh_messages()
    @msgs_list.clear
    msgs = @client.get_messages()
    msgs.each do |msg|
        @msgs_list.append do
          p = para "#{msg.subject.force_encoding("utf-8")}", margin: 10
          p.click {|| open_email msg }
        end
    end
  end

  @msgs_list = stack margin: 10
  @client = IMAPClient.new
  refresh_messages
end
