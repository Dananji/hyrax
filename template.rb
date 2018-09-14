gem 'hyrax', '1.1.1'

run 'bundle install'

generate 'hyrax:install', '-f'

rails_command 'db:migrate'
rails_command 'hyrax:workflow:load'
