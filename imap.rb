require './lib/imap_client'
require './lib/smtp'

class EmailWindow < Shoes::Widget

  def initialize(email)
    stack margin: 10 do
        flow do
            reply = button 'Reply'
            reply.click {|| owner.open_new_letter(email) }
            delete = button 'Delete'
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
              html_button = button 'Open in browser'
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
    end
  end

  def attachments(email)
      if email.part.is_a? Multipart
          attachs = email.part.parts.select {|p| p.is_a? FilePart}
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

  def open_new_letter(email = nil)
    window do
      stack margin: 10 do
        flow margin: 10 do
            para 'From (Name)'
            @from_name = edit_line
            para 'From (Address)'
            @from_adress = edit_line
        end
        flow margin: 10 do
            para 'Recepient'
            @to_name = edit_line text: email&.from&.name
            para 'Address'
            @to_address = edit_line
            @to_address.text = email&.from&.address
        end
        flow margin: 10 do
          para 'Subject'
          @subject = edit_line
        end
        para 'Message'
        @body_field = edit_box

        attachs = []
        flow margin: 10 do
          add_file = button ('Add file...')
          files_list = para
          add_file.click do
            attachs << ask_open_file
            files_list.text = attachs.join ' '
          end
        end

        send = button 'Send'
        send.click do
            from = EmailContact.new @from_adress.text, @from_name.text
            to = EmailContact.new @to_address.text, @to_name.text
            message = SMTPMessage.new from, to, @subject.text, @body_field.text, Date.new, attachs
            SMTPClient.send_message(message)
            close
        end
      end
    end
  end

  refresh_btn = button 'Refresh'
  refresh_btn.click {|| refresh_messages }

  button ('New letter') { open_new_letter }

  @msgs_list = stack margin: 10
  @client = IMAPClient.new
  refresh_messages
end
