namespace :test do
  task all: :environment do
    sh 'rails lint', verbose: false
    sh 'rails test', verbose: false
  end
end

task lint: :environment do
  sh 'rails lint:ruby', verbose: false
  sh 'rails lint:html', verbose: false
  sh 'rails lint:css', verbose: false
  sh 'rails lint:js', verbose: false
  sh 'rails lint:security', verbose: false
end

namespace :lint do
  task ruby: :environment do
    sh 'bundle exec rubocop --parallel', verbose: false
  end

  task html: :environment do
    sh 'bundle exec erblint "app/views/**/*.*.erb"', verbose: false
  end

  task css: :environment do
    sh 'yarn run stylelint "**/*.{css,scss}"', verbose: false
  end

  task js: :environment do
    sh 'yarn run eslint "app/javascript/**/*.js"', verbose: false
  end

  task security: :environment do
    sh 'bundle exec bundle-audit update', verbose: false
    sh 'bundle exec bundle-audit', verbose: false
    sh 'yarn audit', verbose: false

    # CI=true prevents paging of the output as it would block the build process
    # https://github.com/presidentbeef/brakeman/blob/master/lib/brakeman/report/pager.rb#L71
    sh 'CI=true bundle exec brakeman', verbose: false
  end
end
