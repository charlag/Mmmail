class EmailContact
    attr_reader :address, :name

    def initialize(address, name)
      @address = address
      @name = name
    end

    def self.from_string(string)
        email_in_braces = string[/<(.*?)>/m, 1]
        if email_in_braces != nil
            new email_in_braces, string.partition('<').first.strip
        else
            new string, nil
        end
    end

    def to_s
        unless @name.nil?
            return "#{@name} <#{@address}>"
        else
            return @address
        end
    end
end
