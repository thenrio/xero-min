module XeroMin
  module Urls
    # Public : use plural to get a collection or use singular and value
    # url_for(:invoices) OR url_for(invoice: 'INV-001')
    def url_for(sym_or_hash)
      key, value = case sym_or_hash
      when Hash
        sym_or_hash.first
      else
        sym_or_hash
      end
      base = "https://api.xero.com/api.xro/2.0/#{key.to_s.capitalize}"
      value ? "#{base}s/#{value}" : base
    end
  end
end