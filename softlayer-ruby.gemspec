--- !ruby/object:Gem::Specification 
name: softlayer-ruby
version: !ruby/object:Gem::Version 
  version: 0.8.0
platform: ruby
authors: 
- James Nuckolls
autorequire: softlayer
bindir: bin
cert_chain: []

date: 2009-04-28 00:00:00 -05:00
default_executable: 
dependencies: 
- !ruby/object:Gem::Dependency 
  name: soap4r
  type: :runtime
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - ">="
      - !ruby/object:Gem::Version 
        version: 1.5.0
    version: 
description: 
email: afeIfz.drtgcE@what.net
executables: []

extensions: []

extra_rdoc_files: 
- README
- LICENSE
- Changes
files: 
- lib/softlayer.rb
- lib/softlayer/baseclass.rb
- lib/softlayer/util.rb
- sample/nascapacity.rb
- sample/billingreport.rb
- sample/objectmask.rb
- sample/resultlimit.rb
- sample/cdnlayerupload.rb
- README
- LICENSE
- Changes
has_rdoc: true
homepage: http://github.com/jamesn/softlayer-ruby
post_install_message: 
rdoc_options: []

require_paths: 
- lib
required_ruby_version: !ruby/object:Gem::Requirement 
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      version: "0"
  version: 
required_rubygems_version: !ruby/object:Gem::Requirement 
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      version: "0"
  version: 
requirements: []

rubyforge_project: 
rubygems_version: 1.3.1
signing_key: 
specification_version: 2
summary: A module and class factory for SoftLayer's customer portal API
test_files: []

