namespace :test do
  task full: :environment do
    sh 'rails lint', verbose: false
    sh 'rails test:all', verbose: false
  end
end

task lint: :environment do
  sh 'rails lint:ruby', verbose: false
  sh 'rails lint:erb', verbose: false
  sh 'rails lint:css', verbose: false
  sh 'rails lint:js', verbose: false
  sh 'rails lint:security', verbose: false
end

namespace :lint do
  task ruby: :environment do
    sh 'bundle exec rubocop %s' % [(autocorrect? ? '--auto-correct' : '--parallel')], verbose: false
  end

  task erb: :environment do
    sh 'bundle exec erblint %s "app/views/**/*.*.erb"' % [(autocorrect? ? '--autocorrect' : '')], verbose: false
  end

  task css: :environment do
    sh 'yarn run stylelint %s "**/*.{css,scss}"' % [(autocorrect? ? '--fix' : '')], verbose: false
  end

  task js: :environment do
    sh 'yarn run eslint %s "app/assets/javascripts/**/*.js"' % [(autocorrect? ? '--fix' : '')], verbose: false
  end

  task security: :environment do
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

task fix: :environment do
  # Dummy task for the `fix` argument
end
