#encoding: utf-8
desc 'Generate HTML of Kubevirt.io'
task :build do
    puts "Building"
    sh "bundle exec jekyll build"
end

namespace :links do
    require 'html-proofer'

    desc 'Checks html files looking for external dead links'
    task :test_external => :build do
        options = {
            :assume_extension   => true,
            :only_4xx           => true,
            :log_level          => :info,
            :internal_domains   => ["https://instructor.labs.sysdeseng.com"],
            :external_only      => true,
            :url_swap           => {
                                    'https://kubevirt.io/' => '',
                                    }
        }
        puts "Checking External links..."
        HTMLProofer.check_directory("./_site", options).run
    end

    desc 'Checks html files looking for internal dead links'
    task :test_internal => :build do
        options = {
            :assume_extension   => true,
            :only_4xx           => true,
            :allow_hash_href    => true,
            :log_level          => :info,
            :disable_external   => true
        }
        puts "Checking Internal links..."
        HTMLProofer.check_directory("./_site", options).run
    end
end

desc 'The default task will execute all tests in a row'
task :default => ['links:test_external', 'links:test_internal']
