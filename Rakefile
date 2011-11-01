require 'rubygems'
require 'rubygems/package_task'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rake/packagetask'
require 'rake/contrib/rubyforgepublisher'
require 'fileutils'
require 'hoe'
include FileUtils
require File.join(File.dirname(__FILE__), 'lib', 'objectiveflickr', 'version')

AUTHOR = ["lukhnos", "itsZero"]  # can also be an array of Authors
EMAIL = "lukhnos@gmail.com"
DESCRIPTION = "objectiveflickr is a minimalistic Flickr API library that uses REST-style calls and receives JSON response blocks, resulting in very concise code. Named so in order to echo another Flickr library of mine, under the same name, developed for Objective-C."
GEM_NAME = "objectiveflickr" # what ppl will type to install your gem
RUBYFORGE_PROJECT = "objectiveflickr" # The unix name for your project
HOMEPATH = "http://#{RUBYFORGE_PROJECT}.rubyforge.org"
RELEASE_TYPES = %w( gem ) # can use: gem, tar, zip


NAME = "objectiveflickr"
REV = nil # UNCOMMENT IF REQUIRED: File.read(".svn/entries")[/committed-rev="(d+)"/, 1] rescue nil
VERS = ENV['VERSION'] || (ObjectiveFlickr::VERSION::STRING + (REV ? ".#{REV}" : ""))
CLEAN.include ['**/.*.sw?', '*.gem', '.config']
RDOC_OPTS = ['--quiet', '--title', "objectiveflickr documentation",
    "--opname", "index.html",
    "--line-numbers", 
    "--main", "README",
    "--inline-source"]

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
hoe = Hoe.spec GEM_NAME do |p|
  p.version = VERS
  p.author = AUTHOR 
  p.description = DESCRIPTION
  p.email = EMAIL
  p.summary = DESCRIPTION
  p.url = HOMEPATH
  p.rubyforge_name = RUBYFORGE_PROJECT if RUBYFORGE_PROJECT
  p.test_globs = ["test/**/*_test.rb"]
  p.clean_globs = CLEAN  #An array of file patterns to delete on clean.
  
  p.extra_deps = [["json", ">= 0"], ["oauth", ">= 0"]]
  
  # == Optional
  #p.changes        - A description of the release's latest changes.
  #p.extra_deps     - An array of rubygem dependencies.
  #p.spec_extras    - A hash of extra values to set in the gemspec.
end
          
