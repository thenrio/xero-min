module XeroMin
  module Urls
    def url_for(sym)
      "https://api.xero.com/api.xro/2.0/#{sym.to_s.capitalize}"
    end
  end
end