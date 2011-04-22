# describe 'extract_invoice_id' do
#   it 'should extract InvoiceNumber from happy xml, under xpath' do
#     xml = <<XML
# <Response>
# <Invoices>
#   <Invoice>
#     <InvoiceNumber>INV-0011</InvoiceNumber>
#   </Invoice>
# </Invoices>
# </Response>
# XML
#     response = HttpDuck.new(200, xml)
#     @connector.extract_invoice_id(response).should == 'INV-0011'
#   end
# end