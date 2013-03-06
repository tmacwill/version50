Gem::Specification.new do |s|
  s.name = 'version50'
  s.version = '0.0.1'
  s.date = '2012-12-16'
  s.summary  = 'A student-friendly SCM abstraction layer.'
  s.description = 'A student-friendly SCM abstraction layer.'
  s.authors = ['Tommy MacWilliam']
  s.email = 'tmacwilliam@cs.harvard.edu'
  s.files = ['lib/version50.rb', 'lib/version50/git.rb', 'lib/version50/scm.rb']
  s.homepage = 'https://github.com/tmacwill/version50'
  s.executables << "v50"
  s.add_dependency 'json'
  s.add_dependency 'highline'
end

