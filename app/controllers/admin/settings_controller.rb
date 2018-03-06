module Admin
  class SettingsController < BaseController
    # show settings edit form
    def index
    end

    # save all settings defined in settings form
    def save_settings
      (params[:setting] || []).each do |key, val|
        setting = Setting.find_by_key(key)
        setting = Setting.create!(key: key) unless setting
        if val.is_a?(ActionDispatch::Http::UploadedFile) # image setting value
          setting.update(image: val)
        else # text setting value
          setting.update(value: (val.is_a?(Array) ? val.join(',') : val))
        end
      end
      
      # clear file values
      (params[:clear_file] || {}).each do |setting_key, v|
        setting = Setting.find_by_key(setting_key)
        setting.update(image: nil) if setting
      end
      
      # delete greeting countries
      (params[:del_country] || {}).each do |country, v|
        Setting.where('settings.key like ?', "#{country}_%_art_country").destroy_all
      end
      
      Setting.reset_caches
      redirect_to url_for(action: :index), notice: 'Settings were successfully saved!'
    end
  end
end
