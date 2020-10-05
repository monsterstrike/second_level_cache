require "msgpack"

module SecondLevelCache
  class Serializer
    SERIALIZER_VERSION = 1
    # FIXME: update msgpack to 0.7 or higher
    # should use MessagePack::Factory#register_type
    #class TimeWithZonePacker
      #def self.pack(x)
        #sec, min, hour, day, month, year = x.to_a
        #[year, month, day, hour, min, sec, x.utc_offset].pack("NNNNNNN")
      #end
    #end

    #class TimeWithZoneUnpacker
      #def self.unpack(x)
        #year, month, day, hour, min, sec, utc_offset = x.unpack("NNNNNNN")
        #Time.new(year, month, day, hour, min, sec, utc_offset)
      #end
    #end

    class << self
      #def factory
        #if defined? @factory
          #@factory
        #else
          #@factory ||= MessagePack::Factory.new
          #@factory.register_type(0x01, Time, packer: ->(x) { TimeWithZonePacker.pack(x) }, unpacker: ->(x) { TimeWithZoneUnpacker.unpack(x) })
          #@factory
        #end
      #end

      #def packer
        #factory.packer.tap { |x| x.clear }
      #end

      #def unpacker
        #factory.unpacker.tap { |x| x.reset }
      #end

      def dump(record)
        types = record.class.columns_hash
        obj = record.attributes.each_with_object({}) do |(key, value), obj|
          if types[key].type == :datetime && value.present?
            sec, min, hour, day, month, year = value.to_a
            obj[key] = [year, month, day, hour, min, sec, value.utc_offset]
          elsif types[key].type == :date && value.present?
            obj[key] = value.to_s
          else
            obj[key] = value
          end
        end

        MessagePack.dump([SERIALIZER_VERSION, *obj.values_at(*sorted_columns(record.class))])
      end

      def load(klass, serialized)
        loaded = MessagePack.load(serialized)
        case loaded[0]
        when 1
          load_v1(klass, loaded.from(1))
        else
          loaded
        end
      end

      def load_v1(klass, loaded)
        obj = Hash[sorted_columns(klass).zip(loaded)]
        types = klass.columns_hash
        obj.each do |key, value|
          if types[key].type == :datetime && value.present?
            year, month, day, hour, min, sec, utc_offset = value
            obj[key] = Time.new(year, month, day, hour, min, sec, utc_offset)
          elsif types[key].type == :date && value.present?
            obj[key] = Date.parse(value)
          end
        end
        obj
      end

      protected

      def sorted_columns(klass)
        klass.columns.map(&:name).sort
      end
    end
  end
end
