tiny lib for xero

existing ruby xero libraires are crowded with models : Payroll, Contact, Invoice that map each xml structure available through api

But what if I dont care with Payroll or I have already one ... Will I have to build an XXX::Invoice with mine ?

Here is the minimal workflow for a POST request to xero :

* send a http request, with xml in params (in body for PUT, ohnoes oauth)
* sign request with oauth
* parse response

What this library does is the minimal wire, that is a functional api to GET|POST|PUT any xero call, with the following workflow

* use your model to build proper xml
* call xero-min
* parse response to get data your app need

Library was built and tested for a private app

Abstract
========
Uses

* typhoeus, to configure uri, headers, body, params
* nokogiri to parse response

Get some data
=============
You will get a Nokogiri node.

Then you can scrap it and extract what you require, no more, no less

extract [id, name] for each contact
-----------------------------------
    doc = client.get! :contacts
    doc.xpath('//Contact').map{|c| ['ContactID', 'Name'].map{|e| c.xpath("./#{e}").text}}

Post! some data
===============
lib is raw : you have to post well xml, as it is what xero understand

    client.post! :contacts, body: xml

    client.post! 'https://api.xero.com/api.xro/2.0/contacts', body: xml

What xml to post! or put! ?
---------------------------
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


What is the return value from post! or get! ?
=============================================
It is a Nokogiri node if post is success, extract what you need

    invoice.ref = node.xpath('/Response/Invoices/Invoice/InvoiceNumber').first.content

Else, it raise a XeroMin::Problem with a message

Caveats
=======
use PUT to post data ... or use POST + params: {xml: xml} rather than body: xml with following patch : https://github.com/oauth/oauth-ruby/pull/24

