module ModelHiddenSupportConcern extend ActiveSupport::Concern
  included do
    default_scope { where(deleted_at: nil) }
  end

  class_methods do
    # include hidden elements into current collection
    def with_hidden
      if ActiveRecord::VERSION::STRING >= "4.1"
        return unscope where: :deleted_at
      end
      all.tap { |x| x.default_scoped = false }
    end

    # exclude non hidden elements
    def only_hidden
      with_hidden.where.not(deleted_at: nil)
    end

    # restore a collection of hidden objects
    def restore_hidden!
      only_hidden.update_all(deleted_at: nil)
    end
    
    # makes hidden all elements from current collection
    def make_hidden!
      update_all(deleted_at: Time.current)
    end
  end
  
  # restores an specific model into active model
  def restore_hidden!
    update_column(:deleted_at, nil)
  end

  # makes hidden current element
  def make_hidden!
    update_column(:deleted_at, Time.current)
  end
end