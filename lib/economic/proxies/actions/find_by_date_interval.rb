module Economic
  module FindByDateInterval

    # Returns entity objects for a given interval of days.
    def find_by_date_interval(from, unto)
      response = session.request entity_class.soap_action("FindByDateInterval") do
        soap.body = {
          'first' => from.iso8601,
          'last' => unto.iso8601,
          :order! => ['first', 'last']
        }
      end

      handle_key = "#{Support::String.underscore(entity_class_name)}_handle".intern
      handles = [ response[handle_key] ].flatten.reject(&:blank?).collect do |handle|
        Entity::Handle.new(handle)
      end

      get_data_array(handles).collect do |entity_hash|
        entity = build(entity_hash)
        entity.persisted = true
        entity
      end
    end

  end
end
