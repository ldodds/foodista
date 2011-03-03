class Util
  
  #Util code for cleaning up whitespace, newlines, etc
  def Util.clean_ws(s)
    cleaned = s.gsub /^\r\n/, ""
    cleaned.gsub! /\n/, ""    
    cleaned.gsub! /\s{2,}/, " "
    cleaned.gsub! /^\s/, ""
    
    illegal = /\x00|\x01|\x02|\x03|\x04|\x05|\x06|\x07|\x08|\x0B|
    \x0C|\x0E|\x0F|\x10|\x11|\x12|\x13|\x14|\x15|\x16|\x17|\x18|\x19|\x1A|
    \x1B|\x1C|\x1D|\x1E|\x1F/
    
    cleaned.gsub! illegal, " "    
    if cleaned == "" or cleaned == " "
      return nil
    end
    return cleaned
  end  
  
  
  def Util.slug(s)
    normalized = s.downcase
    normalized.gsub! /\s+/, "-"
    normalized.gsub! /\(|\)/, ""
    
    normalized.gsub! /&/, ""
    normalized.gsub! /\?/, ""
    normalized.gsub! /\=/, ""
    normalized.gsub! /\:/, ""
    normalized.gsub! /,/, ""
    
    return normalized    
  end

  def Util.canonicalize(path)
    if path.start_with?("http")
      return path
    end  
    return "http://data.kasabi.com/dataset/foodista#{path}"
  end
    
end