module Ibanity
  module Xs2a
    class CustomerAccessToken < ::Ibanity::BaseResource
      def self.create(idempotency_key: nil, **attributes)
        path = ::Ibanity.xs2a_api_schema["customerAccessTokens"]
        uri = ::Ibanity.client.build_uri(path)
        create_by_uri(uri: uri, resource_type: "customerAccessToken", attributes: attributes, idempotency_key: idempotency_key)
      end
    end
  end
end
