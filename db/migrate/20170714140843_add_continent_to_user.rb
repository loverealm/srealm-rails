class AddContinentToUser < ActiveRecord::Migration
  def change
    User.unscoped.where.not(country: nil).find_each do|user|
      user.update(continent: ISO3166::Country.new(user.country).try(:region))
      meta = user.meta_info
      meta[:continent] = ISO3166::Country.new(user.country).try(:continent)
      user.update_column(:meta_info, meta)
    end
  end
end
