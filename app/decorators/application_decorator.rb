class ApplicationDecorator < Draper::Decorator
  # permit to set custom current_user for decorators
  def set_current_user(user)
    @current_user = user
  end
  
  def current_user
    @current_user || h.current_user
  end
  
  def to_json(options = {})
    object.to_json(options)
  end
end