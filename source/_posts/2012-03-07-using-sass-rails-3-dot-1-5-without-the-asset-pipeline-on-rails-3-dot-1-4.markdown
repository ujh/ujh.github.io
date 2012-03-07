---
layout: post
title: "Using sass-rails 3.1.5 without the asset pipeline on Rails 3.1.4"
date: 2012-03-07 17:29
comments: true
categories: [ruby, sass, sass-rails, ruby on rails, hack, workaround]
---
I'm currently upgrading one of the Ruby on Rails apps from Rails 3.0 to Rails 3.1. As it so happens we're using [ActiveAdmin](http://activeadmin.info/) with it which requires [sass-rails](https://github.com/rails/sass-rails) on Rails 3.1. At the time of writing the latest version of [sass-rails](https://github.com/rails/sass-rails) is 3.1.5 and it requires the asset pipeline to be enabled. But I don't want to upgrade from [jammit](http://documentcloud.github.com/jammit/) at this time so I have to disable the asset pipeline. But with the asset pipeline disabled the app can't start due to [sass-rails](https://github.com/rails/sass-rails). So here's what I needed to do to make it work.

### config/environment.rb

I had to change it so that it looks like the code snippet below. Basically this fakes the asset pipeline for the benefit of [sass-rails](https://github.com/rails/sass-rails).

```ruby
# Load the rails application
require File.expand_path('../application', __FILE__)

Webanalyzer::Application.assets = Struct.new(:context_class) do
  def append_path(*args); end
end.new(Class.new)

# Initialize the rails application
Webanalyzer::Application.initialize!
```

### config/application.rb

Disable compilation of the assets alongside disabling the asset pipeline as a whole.

```ruby
config.assets.enabled = false
config.assets.compile = false
```

### Done!

The two small changes fixed [sass-rails](https://github.com/rails/sass-rails) without the asset pipeline for now. Hopefully [pull request #84](https://github.com/rails/sass-rails/pull/84) will be merged into sass-rails soon and a new version will be released so that this hack won't be necessary. Until then this is the most basic fix I could come up with.