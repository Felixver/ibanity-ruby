module Ibanity
  class BaseResource < OpenStruct
    def self.create_by_uri(uri, resource_type, attributes)
      payload = {
        data: {
          type:       resource_type,
          attributes: attributes
        }
      }
      raw_item = Ibanity.client.post(uri, payload)
      new(raw_item["data"])
    end

    def self.all_by_uri(uri)
      raw_items = Ibanity.client.get(uri)
      raw_items["data"].map do |raw_item|
        new(raw_item)
      end
    end

    def self.find_by_uri(uri)
      new(find_raw_by_uri(uri))
    end

    def self.find_raw_by_uri(uri)
      raw_item = Ibanity.client.get(uri)
      raw_item["data"]
    end

    def self.destroy_by_uri(uri)
      raw_item = Ibanity.client.delete(uri)
      new(raw_item["data"])
    end

    def initialize(raw)
      attributes = prepare_attributes(raw)
      super(attributes)

      relationships = raw["relationships"] || {}
      setup_relationships(relationships)
    end

    def reload!
      reloaded   = self.class.find_raw_by_uri(uri)
      attributes = prepare_attributes(reloaded)
      attributes.each do |key, value|
        self[key] = value
      end
      self
    end

    private

    def prepare_attributes(raw)
      base = {
        "id"  => raw["id"],
        "uri" => raw["links"]["self"]
      }
      attributes           = raw["attributes"]    || {}
      meta                 = raw["meta"]          || {}
      params               = base.merge(attributes).merge(meta)
      Ibanity::Util.underscorize_hash(params)
    end

    def setup_relationships(relationships)
      relationships.each do |key, relationship|
        if relationship["data"]
          klass = Ibanity.const_get(Ibanity::Util.camelize(key))
          method_name = Ibanity::Util.underscore(key)
          define_singleton_method(method_name) do
            klass.find_by_uri(relationship["links"]["related"])
          end
          self[Ibanity::Util.underscore("#{key}_id")] = relationship["data"]["id"]
        else
          singular_key = key[0..-2]
          klass        = Ibanity.const_get(Ibanity::Util.camelize(singular_key))
          method_name  = Ibanity::Util.underscore(key)
          define_singleton_method(method_name) do
            uri = relationship["links"]["related"]
            klass.all_by_uri(uri)
          end
        end
      end
    end
  end
end
