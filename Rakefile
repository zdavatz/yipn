require 'rubygems'
require 'fileutils'
require 'rake/clean'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/test*.rb']
end

class Rake::Task
  def overwrite(&block)
    @actions.clear
    enhance(&block)
  end
end

# vim: syntax=ruby
