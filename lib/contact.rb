class EmailContact
    attr_reader :address, :name

    def initialize(string)
        email_in_braces = string[/<(.*?)>/m, 1]
        if email_in_braces != nil
            @address = email_in_braces
            @name = string.partition('<').first.strip
        else
            @address = string
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
