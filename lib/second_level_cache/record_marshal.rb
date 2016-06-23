# -*- encoding : utf-8 -*-
module RecordMarshal
  class << self
    # dump ActiveRecord instace with only attributes.
    # ["User",
    #  {"id"=>30,
    #  "email"=>"dddssddd@gmail.com",
    #  "created_at"=>2012-07-25 18:25:57 UTC
    #  }
    # ]

    def dump(record)
      [
       record.class.name,
       record.attributes
      ]
    end

    # load a cached record
    def load(serialized)
      return unless serialized

      klass, attributes = serialized[0].constantize, serialized[1]

      klass.columns.select { |c| c.type == :datetime }.each do |datetime_column|
        if attributes[datetime_column.name].present? && attributes[datetime_column.name].is_a?(Fixnum)
          attributes[datetime_column.name] = Time.at(attributes[datetime_column.name])
        end
      end

      klass.instantiate(attributes)
    end
  end
end
