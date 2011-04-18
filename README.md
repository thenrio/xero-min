ruby-1.9.2-p136 :003 > load 'xero/client.rb'; client=Xero::Client.new


ruby-1.9.2-p136 :013 > me={name: 'Thierry Henrio', first_name: 'Thierry', last_name: 'Henrio', email: 'thierry.henrio@gmail.com'}
 => {:name=>"Thierry Henrio", :first_name=>"Thierry", :last_name=>"Henrio", :email=>"thierry.henrio@gmail.com"}
ruby-1.9.2-p136 :014 >


ruby-1.9.2-p136 :002 > invoice = {contact: {id: '7cdf4fb4-f8ed-48e7-a989-56170d4ffb30'}, items: [{price: 220, quantity: 5, code: 'AGF11E'}]}
 => {:contact=>{:name=>"Thierry Henrio"}, :items=>[{:price=>220, :quantity=>5, :code=>"AGF11E"}]}
