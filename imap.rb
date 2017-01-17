require './lib/imap_client'

class GUIHelper
    def initialize(app)
        @app = app
    end

    def open_email(email)
        @app.window do
            stack do
                flow height: 10 do
                    button "Reply"
                    button "Delete"
                end
                para email.to_s
                GUIHelper.attachments app, email
            end
        end
    end

    def self.attachments(app, email)
        if email.part.is_a? Multipart
            attachs = email.part.parts.select {|p| p.is_a? ImagePart}
            unless attachs.empty?
                app.flow height: 20 do
                    attachs.each do |a|
                        app.button a.name
                    end
                end
            end
        end
    end
end

Shoes.app height: 450, width: 650 do
  client = IMAPClient.new
  helper = GUIHelper.new(self)

  stack margin: 10 do
      client.get_messages().each do |msg|
          p = para "#{msg.subject.force_encoding("utf-8")}", margin: 10
          p.click {|| helper.open_email msg }
      end
  end
end
