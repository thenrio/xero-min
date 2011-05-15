# -*- encoding: utf-8 -*-
$:.unshift File.expand_path("../lib", __FILE__)
require "xero-min/version"

Gem::Specification.new do |s|
  s.name        = "xero-min"
  s.version     = XeroMin::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Thierry Henrio"]
  s.email       = ["thierry.henrio@gmail.com"]
  s.homepage    = "https://github.com/thierryhenrio/xero-min"
  s.summary     = <<-EOS
    Minimal xero lib, no models, just wires
  EOS
  s.description = <<-EOS
    Wires are oauth-ruby, typhoeus, nokogiri
  EOS
  s.rubyforge_project = "xero-min"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'oauth', '~> 0.4'
  s.add_dependency 'nokogiri', '~> 1'
  s.add_dependency 'typhoeus', '~> 0.2'
  s.add_dependency 'escape_utils', '~> 0.2'
  s.add_development_dependency 'rspec', '~> 2'
end
