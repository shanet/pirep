# rubocop:disable Rails/RakeEnvironment

desc 'Run all linters'
task :lint do
  sh 'rails lint:ruby', verbose: false
  sh 'rails lint:erb', verbose: false
  sh 'rails lint:css', verbose: false
  sh 'rails lint:js', verbose: false
  sh 'rails lint:security', verbose: false
end

namespace :lint do
  desc 'Run Ruby linter'
  task :ruby do
    sh 'bundle exec rubocop %s' % [(autocorrect? ? '--autocorrect' : '--parallel')], verbose: false
  end

  desc 'Run ERB linter'
  task :erb do
    sh 'bundle exec erblint %s "app/views/**/*.*.erb"' % [(autocorrect? ? '--autocorrect' : '')], verbose: false
  end

  desc 'Run CSS linter'
  task :css do
    sh 'yarn run stylelint %s "app/assets/stylesheets/**/*.{css,scss}"' % [(autocorrect? ? '--fix' : '')], verbose: false
  end

  desc 'Run JavaScript linter'
  task :js do
    sh 'yarn run eslint %s "app/assets/javascripts/**/*.js"' % [(autocorrect? ? '--fix' : '')], verbose: false
  end

  desc 'Run security audits'
  task :security do
    sh 'bundle exec bundle-audit update', verbose: false
    sh 'bundle exec bundle-audit', verbose: false
    sh 'yarn audit', verbose: false

    # CI=true prevents paging of the output as it would block the build process
    # https://github.com/presidentbeef/brakeman/blob/master/lib/brakeman/report/pager.rb#L71
    sh 'CI=true bundle exec brakeman', verbose: false
  end

  def autocorrect?
    return ARGV&.first == 'fix'
  end
end

task :fix do
  # Dummy task for the `fix` argument
end

# rubocop:enable Rails/RakeEnvironment
