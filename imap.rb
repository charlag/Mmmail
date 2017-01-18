require './lib/imap_client'

class EmailWindow < Shoes::Widget

  def initialize(email)
    stack margin: 10 do
        flow do
            reply = button "Reply"
            reply.click {|| open_reply(email) }
            delete = button "Delete"
            delete.click {|| delete(email) }


            if email.part && email.part.is_a?(MultipartAlternative)
              html_index = email.part.parts.index { |p| p.is_a?(HtmlPart)}
              if html_index
                html_part = email.part.parts[html_index]
              end
            elsif email.part.is_a?(HtmlPart)
              html_part = email.part
            end

            unless html_part.nil?
              html_button = button "Open in browser"
              html_button.click do
                html_name = Time.new.to_i.to_s + '.html'
                full_path = File.expand_path(html_name, '~/Downloads')
                File.open(full_path, 'w+') do |f|
                  f.write(html_part)
                end
                spawn("open #{full_path}")
              end
            end
        end
        para email.to_s
        attachments email
        print_parts(email.part)
    end
  end

  def print_parts(part, padding = 0)
    if part.is_a?(Multipart)
      part.parts.each {|part| print_parts(part, padding + 1) }
    else
      puts " ".ljust(padding) + part.class.name
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
