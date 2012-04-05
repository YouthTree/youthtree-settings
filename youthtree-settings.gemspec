# -*- encoding: utf-8 -*-

require File.expand_path('lib/youth_tree/settings', File.dirname(__FILE__))

Gem::Specification.new do |s|

  s.name          = "youthtree-settings"
  s.summary       = "Simple Settings for Rails Applications"
  s.description   = %Q{Lets you use config/settings.yml in a rails application to manage settings on a per-env basis.}
  s.authors       = ["Darcy Laycock"]
  s.email         = ["sutto@sutto.net"]
  s.homepage      = "http://github.com/YouthTree/youthtree-settings"
  s.files         = `git ls-files`.split($\)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]
  s.version       = YouthTree::Settings::VERSION.dup
  s.add_dependency "activesupport", "~> 3.0.1"

end