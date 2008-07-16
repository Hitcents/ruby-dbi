module DBI
    class TypeUtil
        @@conversions = { }

        def self.register_conversion(driver_name, &block)
            raise "Must provide a block" unless block_given?
            @@conversions[driver_name] = block
        end

        def self.convert(driver_name, obj)
            newobj = obj
            if @@conversions[driver_name]
                newobj = @@conversions[driver_name].call(obj)
            end
            if newobj.object_id == obj.object_id
                return @@conversions["default"].call(newobj)
            end

            return newobj
        end

        def self.type_name_to_module(type_name)
            case type_name
            when /^int(?:\d+|eger)?$/i
                DBI::Type::Integer
            when /^varchar$/i, /^character varying$/i
                DBI::Type::Varchar
            when /^(?:float|real)$/i
                DBI::Type::Float
            when /^bool(?:ean)?$/i, /^tinyint$/i
                DBI::Type::Boolean
            when /^time(?:stamp(?:tz)?)?$/i
                DBI::Type::Timestamp
            else
                DBI::Type::Varchar
            end
        end
    end
end

DBI::TypeUtil.register_conversion("default") do |obj|
    case obj
    when DBI::Binary # these need to be handled specially by the driver
        obj
    when ::NilClass
        nil
    when ::TrueClass
        "'1'"
    when ::FalseClass
        "'0'"
    when ::Time, ::Date, ::DateTime
        "'#{::DateTime.parse(obj.to_s).strftime("%m/%d/%Y %H:%M:%S")}'"
    when ::String
        obj = obj.gsub(/'/) { "''" }
        "'#{obj}'"
    when ::Numeric
        obj.to_s
    else
        "'#{obj.to_s}'"
    end
end
