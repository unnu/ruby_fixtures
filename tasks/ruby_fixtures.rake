desc "Generate the yaml fixture files out of test/fixtures.rb"

namespace "db:test" do
  task :ruby_fixtures do
    RAILS_ENV = 'test'
    Rake::Task[:environment].invoke
    Rake::Task['db:test:purge'].invoke
    Rake::Task['db:test:load'].invoke

    RubyFixtures.export
  end
end