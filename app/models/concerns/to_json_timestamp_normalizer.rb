module ToJsonTimestampNormalizer
  extend ActiveSupport::Concern
  included do
    def as_json(options = {})
      options = super(options)
      options = _as_json(options) if self.methods.include?(:_as_json) # permit to add extra attributes in models
      options.tap do |result|
        normalize_timestamps(result)
      end
    end
    
    def normalize_timestamps(hash)
      (%w(created_at updated_at) + (custom_timestamp_attrs rescue [])).select { |x| hash.has_key?(x) }.each do |field|
        hash.merge! field => hash[field].to_i
      end
    end
  end
end