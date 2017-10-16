# README

* Add gems [Pundit](https://github.com/elabs/pundit) and [Devise](https://github.com/plataformatec/devise) to Gemfile
```
gem 'pundit'
gem 'devise'
```

* Bundle it
```
bundle
```

* Install gems
```
rails g pundit:install
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



## Facebook and Google login (optional)

* Add gem [Koala](https://github.com/arsduo/koala) and bundle
* Generate access token in [Facebook](https://developers.facebook.com/tools/explorer)/[Google](https://developers.google.com/oauthplayground) developer playground

#### Generating token in Facebook playground

* Access [Facebook Playground](https://developers.facebook.com/tools/explorer)
* After logging in, click in Get Token > Get User Access Token
* Select **email**, **user_about_me** and any desired extra fields
* Click in **Get Access Token**
* Allow permissions
* Click in submit
* Copy the token in *Access Token* field

#### Generating token in Google playground

* Access [Google Playground](https://developers.google.com/oauthplayground)
* In Step 1 open Google OAuth2 API V2 tab
* Select **/plus.login** and **/plus.me** and click in **Authorize API**
* Login, allow permissions
* In Step 2 click in **Exchange authorization code for tokens**
* Copy generated **id_token** (important: it's the *id_token*, not *access_token*)

#### Login through API

* Route to Facebook login/register: users/auth/omniauth/facebook (PATCH/PUT)
* Route to Google login/register: users/auth/omniauth/google_plus (PATCH/PUT)
* Send your generated token in **oauth_access_token** parameter
* Send the user email in **email** parameter
