class Array
  # delete empty values (null, '') of current array
  def delete_empty
    self.delete_if{|v| !v.present? }
  end
  
  # convert all array values into integer values
  def to_i
    self.map{|v| v.to_i }
  end
  
  def empty_if_include_blank!
    self.replace([]) if self.include? ''
  end
end