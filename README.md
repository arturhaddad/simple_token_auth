# README

* Install [Devise](https://github.com/plataformatec/devise)
```
gem 'devise'
```

* Bundle it
```
bundle
```

* Run the generator
```
rails g devise:install
```

* Add to `config/environments/development.rb`
```
config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
```

* Generate Devise models
```
rails g devise MODEL
```

* Inside lib do:
```
wget https://github.com/arturhaddad/simple_token_auth/archive/master.zip && unzip master.zip 'simple_token_auth-master/generators/*' && rsync -av simple_token_auth-master/generators ./ && rm -rf master.zip && rm -rf simple_token_auth-master
```

* Generate authentication for Devise models
```
rails g authentication MODEL
```

* Migrate database
```
rails db:migrate
```

* After creating your controllers change `< ApplicationController` to `< Api::V1::BaseController`
