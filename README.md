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


Post some data
==============


Get some data
=============

You will get a Nokogiri node.

Then you can scrap it and extract what you require, no more, no less

extract [id, name] for each contact
-----------------------------------
    doc = client.get_contacts
    doc.xpath('//Contact').map{|c| ['ContactID', 'Name'].map{|e| c.xpath("./#{e}").text}}

I attempted to return jsonized struct, and failed... so nokogiri remains best option


