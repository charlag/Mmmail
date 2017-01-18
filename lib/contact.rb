EmailContact = Struct.new(:address, :name) do
    def self.from_string(string)
        email_in_braces = string[/<(.*?)>/m, 1]
        if email_in_braces != nil
            self.new email_in_braces, string.partition('<').first.strip
        else
            self.new string, nil
        end
    end

    def to_s
        unless @name.nil?
            "#{@name} <#{@address}>"
        else
            @address
        end
    end
end
