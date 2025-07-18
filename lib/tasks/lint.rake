# rubocop:disable Rails/RakeEnvironment

desc 'Run all linters'
task :lint do
  sh 'rails lint:ruby', verbose: false
  sh 'rails lint:erb', verbose: false
  sh 'rails lint:css', verbose: false
  sh 'rails lint:js', verbose: false
  sh 'rails lint:terraform', verbose: false
  sh 'rails lint:security', verbose: false
end

namespace :lint do
  desc 'Run Ruby linter'
  task :ruby do
    sh "bundle exec rubocop #{autocorrect? ? '--autocorrect' : '--parallel'}", verbose: false
  end

  desc 'Run ERB linter'
  task :erb do
    sh "bundle exec erb_lint #{'--autocorrect' if autocorrect?} \"app/views/**/*.*.erb\"", verbose: false
  end

  desc 'Run CSS linter'
  task :css do
    sh "yarn run stylelint #{'--fix' if autocorrect?} \"app/assets/stylesheets/**/*.{css,scss}\"", verbose: false
  end

  desc 'Run JavaScript linter'
  task :js do
    sh "yarn run eslint #{'--fix' if autocorrect?} \"app/assets/javascripts/**/*.js\"", verbose: false
  end

  desc 'Run Terraform formatter'
  task :terraform do
    sh "terraform fmt --recursive #{'--diff --check' if ENV['CI']} terraform", verbose: false

    # Check that the linter is installed
    sh 'which terraform-lexicographical-lint > /dev/null 2>&1', verbose: false do |success, _result|
      next if success

      warn 'terraform-lexicographical-lint not found or $GOBIN not in $PATH. Install with: go install github.com/shanet/terraform-lexicographical-lint@latest'
      exit 1
    end

    sh 'terraform-lexicographical-lint terraform', verbose: false
  end

  desc 'Run security audits'
  task :security do
    sh 'bundle exec bundle-audit update', verbose: false
    sh 'bundle exec bundle-audit', verbose: false
    sh 'yarn audit --groups dependencies', verbose: false

    # CI=true prevents paging of the output as it would block the build process
    # https://github.com/presidentbeef/brakeman/blob/master/lib/brakeman/report/pager.rb#L71
    sh 'CI=true bundle exec brakeman', verbose: false
  end

  def autocorrect?
    return ARGV&.first == 'fix'
  end
end

# rubocop:enable Rails/RakeEnvironment
