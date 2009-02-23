require 'rubygems'
require 'snipe/version'
require 'tasks/config'

Snipe::GEM_SPEC = Gem::Specification.new do |spec|
  proj = Configuration.for('project')
  spec.name         = proj.name
  spec.version      = Snipe::VERSION
  
  spec.author       = proj.author
  spec.email        = proj.email
  spec.homepage     = proj.homepage
  spec.summary      = proj.summary
  spec.description  = proj.description
  spec.platform     = Gem::Platform::RUBY

  
  pkg = Configuration.for('packaging')
  spec.files        = pkg.files.all
  spec.executables  = pkg.files.bin.collect { |b| File.basename(b) }

  # add dependencies here
  
  # rubyforge
  spec.add_dependency("beanstalk-client", "~> 1.0.2")
  spec.add_dependency("configuration", "~> 0.0.5")
  spec.add_dependency("curb", "~> 0.1.4")
  spec.add_dependency("daemons", "~> 1.0.10")
  spec.add_dependency("logging", "~> 0.9.6")
  spec.add_dependency("nokogiri", "~> 1.1.1" )

  # github
  spec.add_dependency("jchris-couchrest", "~> 0.12.6" )

  if ext_conf = Configuration.for_if_exist?("extension") then
    spec.extensions << ext_conf.configs
    spec.extensions.flatten!
    spec.require_paths << "ext"
  end
  
  if rdoc = Configuration.for_if_exist?('rdoc') then
    spec.has_rdoc         = true
    spec.extra_rdoc_files = pkg.files.rdoc
    spec.rdoc_options     = rdoc.options + [ "--main" , rdoc.main_page ]
  else
    spec.has_rdoc         = false
  end 

  if test = Configuration.for_if_exist?('testing') then
    spec.test_files       = test.files
  end 

  if rf = Configuration.for_if_exist?('rubyforge') then
    spec.rubyforge_project  = rf.project
  end 

end
