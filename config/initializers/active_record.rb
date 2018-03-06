class ActiveRecord::Base
  after_update :force_touch_if_no_changes
  
  # convert certain current model's attributes into hash
  # sample: to_hash([:id, :title])
  def to_hash(attrs)
    JSON.parse(to_json(only: attrs))
  end
  
  # return a cache key for current model according to current model ID and last updated at
  # key_variant: (String) postfix cache key
  # updated_at_attr: updated at attribute for current model
  # Sample: custom_cache_key("is_liked_by_#{user.id}", 'last_activity_time')
  def custom_cache_key(key_variant, updated_at_attr = 'updated_at')
    ii = self.send(updated_at_attr.to_sym)
    "cache_#{self.class.name.parameterize}-#{id}-#{ii.try(:to_i) || ii}-#{key_variant}"
  end
  
  # return cached value or evaluate instance
  def instance_cache_fetch(key)
    key = "@_cache_#{key}"
    instance_variable_set(key, yield) unless instance_variable_defined?(key)
    instance_variable_get(key)
  end

  # similar to normal where but ignore case sensitive
  def self.where_ignore_case(attrs)
    queries = []
    vals = []
    attrs.each do |attr, val|
      queries << "#{attr.is_a?(Symbol) ? "LOWER(#{self.table_name}.#{attr})" : attr} = ?"
      vals << val.to_s.downcase
    end
    where(queries.join(' AND '), *vals)
  end

  # make query for multiple OR conditionals
  # sample: User.where_or(email: 'owenperedo@gmail.com', phone: '88973666373')
  def self.where_or(attrs)
    queries = []
    vals = []
    attrs.each do |attr, val|
      queries << "#{attr.is_a?(Symbol) ? "#{self.table_name}.#{attr}" : attr} = ?"
      vals << val
    end
    where(queries.join(' OR '), *vals)
  end

  # create a like conditions
  # sample: User.where_like(first_name: 'Owen', last_name: 'own')
  def self.where_like_or(attrs)
    queries = []
    vals = []
    attrs.each do |attr, val|
      queries << "#{attr.is_a?(Symbol) ? "LOWER(#{self.table_name}.#{attr})" : attr} like ?"
      vals << "%#{val.to_s.downcase}%"
    end
    where(queries.join(' OR '), *vals)
  end
  
  # create a like conditions
  # sample: User.where_like(first_name: 'Owen', last_name: 'own')
  def self.where_like(attrs)
    queries = []
    vals = []
    attrs.each do |attr, val|
      queries << "#{attr.is_a?(Symbol) ? "LOWER(#{self.table_name}.#{attr})" : attr} like ?"
      vals << "%#{val.to_s.downcase}%"
    end
    where(queries.join(' AND '), *vals)
  end

  # permit to order records by specific sequences
  def self.order_by_ids(ids)
    order_by = ["case"]
    ids.each_with_index.map do |id, index|
      order_by << "WHEN id='#{id}' THEN #{index}"
    end
    order_by << "end"
    order(order_by.join(" "))
  end
  
  # set order newer to old
  def self.newer
    order(created_at: :desc)
  end
  
  # check if current model is being destroyed by association
  def is_destroyed_by_association?
    destroyed_by_association.present?
  end
  
  private
  # force to update updated_at attribute if there are no changes
  def force_touch_if_no_changes
    touch unless changes.any?
  end

end

module ActiveRecord # fix to support store attributes _changed? status 
  module Store
    module ClassMethods
      alias_method :old_store_accessor, :store_accessor
      def store_accessor(store_attribute, *keys)
        old_store_accessor(store_attribute, keys)
        keys.each do |key|
          define_method :"#{key}_changed?" do
            changes[store_attribute] && changes[store_attribute].map { |v| v.try(:[], key) }.uniq.length > 1
          end
        end
      end
    end
  end
end