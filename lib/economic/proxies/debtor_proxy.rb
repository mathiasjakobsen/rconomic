require "economic/proxies/entity_proxy"
require "economic/proxies/actions/find_by_ci_number"
require "economic/proxies/actions/find_by_handle_with_number"
require "economic/proxies/actions/find_by_number"
require "economic/proxies/actions/find_by_telephone_and_fax_number"

module Economic
  class DebtorProxy < EntityProxy
    include FindByCiNumber
    include FindByHandleWithNumber
    include FindByNumber
    include FindByTelephoneAndFaxNumber

    # Returns the next available debtor number
    def next_available_number
      request :get_next_available_number
    end

    def get_debtor_contacts(debtor_handle)
      handles = fetch_handles(:get_debtor_contacts, debtor_handle)
      build_entities_from_handles(:debtor_contact, handles)
    end

    def get_invoices(debtor_handle, format = :entity)
      handles = fetch_handles(:get_invoices, debtor_handle)
      send("build_#{format}_array_from_handles", *[:invoice, handles])
    end

    def get_orders(debtor_handle, format = :entity)
      handles = fetch_handles(:get_orders, debtor_handle)
      send("build_#{format}_array_from_handles", *[:order, handles])
    end

    def get_current_invoices(debtor_handle, format = :entity)
      handles = fetch_handles(:get_current_invoices, debtor_handle)
      send("build_#{format}_array_from_handles", *[:current_invoice, handles])
    end

    private

    def build_raw_array_from_handles(class_name, handles)
      get_proxy_from_name(class_name).get_data_array(handles)
    end

    def build_hash_array_from_handles(class_name, handles)
      get_proxy_from_name(class_name).get_data_array(handles).map! do |data|
        data.to_hash
      end

    end

    def build_entity_array_from_handles(class_name, handles)
      proxy = get_proxy_from_name(class_name)
      proxy.get_data_array(handles).map! do |data|
        entity = proxy.build(data)
        entity.persisted = true
        entity.partial = false
        entity
      end
    end

    def get_proxy_from_name(class_name)
      camelized_name = class_name.to_s.split('_').map{|e| e.capitalize}.join
      Economic.const_get("#{camelized_name}Proxy").new(owner)
    end

    def fetch_handles(operation, debtor_handle)
      response = request(
        operation,
        "debtorHandle" => {"Number" => debtor_handle.number}
      )
      response.values.flatten.collect! { |handle| Entity::Handle.build(handle) }
    end
  end
end
