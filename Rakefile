require 'rubygems'
Gem::manage_gems

require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
    s.platform  =   Gem::Platform::RUBY
    s.name      =   "softlayer-ruby"
    s.version   =   "0.7.0.0"
    s.authors    =   [ "James Nuckolls" ]
    s.email     =   "jamesn@what.net"
    s.homepage   =   "http://github.com/jamesn/softlayer-ruby"
    s.summary   =   "A module and class factory for SoftLayer's customer portal API"
    s.files     =   FileList['lib/*', 'sample/*'].to_a
    s.require_path  =   "lib"
    s.autorequire   =   "softlayer"
    s.has_rdoc  =   true
    s.extra_rdoc_files  =   ["README", "LICENSE"]
    s.add_dependency('soap4r', '>= 1.5.0')
end
 
Rake::GemPackageTask.new(spec) do |pkg| 
  pkg.need_tar = true
end