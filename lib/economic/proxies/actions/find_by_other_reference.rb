require_relative './../../support/string'

module FindByOtherReference
  def find_by_other_reference(other_reference)
    response = request(:find_by_other_reference, 'otherReference' => other_reference)

    handle_key = "#{Economic::Support::String.underscore(entity_class_name)}_handle".intern
    handles = [response[handle_key]].flatten.reject(&:blank?).collect do |handle|
      Entity::Handle.build(handle)
    end

    get_data_array(handles).collect do |entity_hash|
      entity = build(entity_hash)
      entity.persisted = true
      entity
    end
  end
end
