# YouthTree Settings #

## Installation ##

1. Add "gem 'youthtree-settings'" to your Gemfile
2. Run bundle install

## Usage ##

Simply add a configuration file to `config/settings.yml`
and use the `Settings` object. Note that you can use:

* `Settings.name` - base
* `Settings.name.other` - nested
* `Settings.name.other?` - check for a key

## Configuration ##

Simply put a Yaml file in `config/settings.yml`. As an example:

    ---
    default:
      some_key: 1
      nested: true
    production:
      google_analytics:
        identifier: "UA-XXXXXXXX-X"
      mailer:
        contact_email: "team@site.com"
        from: "noreply@site.com"
        host: "site.com"
        delivery_method: smtp
        smtp_settings:
          address: smtp.gmail.com
          port: 587
          authentication: plain
          enable_starttls_auto: true
          domain: site.com 
          user_name: user@site.com
          password: yourpassword
    development:
      mailer:
        contact_email: "test@site.dev"
        from: "test@site.dev"
        host: "localhost:3000"
        delivery_method: sendmail
    test:
      mailer:
        contact_email: "example@example.com"
        from: "example@example.com"
        host: "example.com"
        delivery_method: test


## Note on Patches/Pull Requests ##
 
1. Fork the project.
2. Make your feature addition or bug fix.
3. Add tests for it. This is important so I don't break it in a future version unintentionally.
4. Commit, do not mess with rakefile, version, or history. (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
5. Send me a pull request. Bonus points for topic branches.

## Copyright ##

Copyright (c) 2010 Youth Tree. See LICENSE for details.
