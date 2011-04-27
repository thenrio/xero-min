tiny lib for xero

xero api is a pain in the ass : params, structure, documentation

existing xero libraires are bloated with models

why ?

I believe we are not comfortable with xml, as xml is not a language supported structure, so go and map xml to class ?

But what if I dont care with Payroll or whatever ?

Do I need some code for it ?

I believe I don't

* send a http request, with optional body and params
* sign request with oauth protocol
* parse response


Abstract
========
Use typhoeus, to configure uri, headers, body, params

Use Nokogiri to parse response.


Get some data
=============

You will get a Nokogiri node.

Then you can scrap it and extract what you require, no more, no less

extract [id, name] for each contact
-----------------------------------
    doc = client.get! :contacts
    doc.xpath('//Contact').map{|c| ['ContactID', 'Name'].map{|e| c.xpath("./#{e}").text}}

note that I attempted to use Accept: application/json, and failed : post and put does not support it, and turning xml to json is as good as xml is ...

Post! some data
===============
lib is raw : you have to post well xml, as it is what xero understand

    client.post! :contacts, body: xml

    client.post! 'https://api.xero.com/api.xro/2.0/contacts', body: xml

What xml to post! ?
-------------------
XeroMin::Erb implements basic xml building

    bill = {id: '4d73c0f91c94a2c47500000a', name: 'Billy', first_name: 'Bill', last_name: 'Kid', email: 'bill@kid.com'}
    xml=erb.render contact: bill

and xml should be

    <Contact>
      <ContactNumber>4d73c0f91c94a2c47500000a</ContactNumber>
      <Name>Billy</Name>
      <FirstName>Bill</FirstName>
      <LastName>Kid</LastName>
      <EmailAddress>bill@kid.com</EmailAddress>
    </Contact>

see XeroMin::Erb source code for precisions, templates for example, documentation

Use anything else you feel more comfortable with

Get!
====
    doc = client.get! :contacts

    doc = 'https://api.xero.com/api.xro/2.0/invoices'

    doc = client.get! "#{client.url_for(:contacts)}/#{bill.id}"


What is the return value from this post! or a get! ?
====================================================
It is a Nokogiri node if post is success, extract what you need

    invoice.ref = node.xpath('/Response/Invoices/Invoice/InvoiceNumber').first.content

Else, it raise a XeroMin::Problem with a message
