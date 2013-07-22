module Economic
  class EntityProxy
    class << self
      # Returns the class this Proxy is a proxy for
      def entity_class
        Economic.const_get(self.entity_class_name)
      end

      def entity_class_name
        proxy_class_name = name.split('::').last
        proxy_class_name.sub(/Proxy$/, '')
      end
    end

    include Enumerable

    attr_reader :owner, :items

    def initialize(owner)
      @owner = owner
      @items = []
    end

    def session
      owner.session
    end

    # Fetches all entities from the API.
    def all
      response = request(:get_all)
      handles = response.values.flatten.collect { |handle| Entity::Handle.build(handle) }

      if handles.size == 1
        # Fetch data for single entity
        find(handles.first)
      elsif handles.size > 1
        # Fetch all data for all the entities
        entity_data = get_data_array(handles)

        # Build Entity objects and add them to the proxy
        entity_data.each do |data|
          entity = build(data)
          entity.persisted = true
        end
      end

      self
    end

    # Returns a new, unpersisted Economic::Entity that has been added to Proxy
    def build(properties = {})
      entity = self.class.entity_class.new(:session => session)

      entity.update_properties(properties)
      entity.partial = false

      self.append(entity)
      initialize_properties_with_values_from_owner(entity)

      entity
    end

    # Returns the class this proxy manages
    def entity_class
      self.class.entity_class
    end

    # Returns the name of the class this proxy manages
    def entity_class_name
      self.class.entity_class_name
    end

    # Fetches Entity data from API and returns an Entity initialized with that data added to Proxy
    def find(handle)
      handle = Entity::Handle.new(handle)
      entity_hash = get_data(handle)
      entity = build(entity_hash)
      entity.persisted = true
      entity
    end

    # Gets data for Entity from the API. Returns Hash with the response data
    def get_data(handle)
      handle = Entity::Handle.new(handle)

      entity_hash = request(:get_data, {
        'entityHandle' => handle.to_hash
      })
      entity_hash
    end

    # Adds item to proxy unless item already exists in the proxy
    def append(item)
      items << item unless items.include?(item)
    end
    alias :<< :append

    def each
      items.each { |i| yield i }
    end

    def empty?
      items.empty?
    end

    # Returns the number of entities in proxy
    def size
      items.size
    end

    # Requests an action from the API endpoint
    def request(action, data = nil)
      session.request(entity_class.soap_action_name(action)) do
        soap.body = data if data
      end
    end

  protected

    # Fetches all data for the given handles. Returns Array with hashes of entity data
    def get_data_array(handles)
      return [] unless handles && handles.any?

      entity_class_name_for_soap_request = entity_class.name.split('::').last
      response = request(:get_data_array, {'entityHandles' => {"#{entity_class_name_for_soap_request}Handle" => handles.collect(&:to_hash)}})
      [response["#{entity_class.key}_data".intern]].flatten
    end

    # Initialize properties of entity with values from owner. Returns entity
    def initialize_properties_with_values_from_owner(entity)
      entity
    end
  end
end
