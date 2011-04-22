module Xero
  module Utils
    def extract_invoice_id(response)
      doc = Nokogiri::XML(response.body)
      extract_from_doc(doc, '/Response/Invoices/Invoice/InvoiceNumber')
    end

    def extract_contact_id(response)
      doc = Nokogiri::XML(response.body)
      extract_from_doc('/Response/Contacts/Contact/ContactID')
    end

    def extract_from_doc(doc, path)
      doc.xpath(path).first.content
    end

    def extract_contacts(response)
      doc = Nokogiri::XML(response.body)
      doc.xpath('/Response/Contacts/Contact')
    end

    module_function :extract_invoice_id, :extract_contact_id, :extract_contacts
  end
end