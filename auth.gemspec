$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "auth/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "auth"
  s.version     = Auth::VERSION
  s.authors     = ["bhargav"]
  s.email       = ["bhargav.r.raut@gmail.com"]
  s.homepage    = "http://github.com/wordjelly/auth"
  s.summary     = "Authentication engine, bundles mongoid, devise, and token authentication"
  s.description = "Simple authentication solution for any rails app."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.6"
  s.add_dependency 'simple_token_authentication', '~> 1.0'
  s.add_dependency 'devise', "~> 4.1.1"
  s.add_dependency 'omniauth'
  s.add_dependency 'omniauth-google-oauth2'
  s.add_dependency 'omniauth-twitter'
  s.add_dependency 'omniauth-facebook'
  s.add_dependency 'omniauth-linkedin'
  s.add_dependency 'request_store'
  s.add_dependency 'thin'
 

end
