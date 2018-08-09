# Rails::Linkage

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/rails/linkage`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails-linkage'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rails-linkage

## Usage

```ruby
#html data attributes
data: {
  linkage: [{trigger: 'selector', attr: '', prefix: '', matcher: '', condition: 'selector to ignore trigger value'}, {...}],
  'linkage-opt': 'or',
  'linkage-combination': 'hook',
  'linkage-keep': 'keep selector'
}

```

```coffescript
#context object
select = {
  name: 'select'
  selector: 'select:not(.selectpicker)'

  #return jquery array
  children: (target_e)->
    $(target_e).find('option')

  all_children: (target_e, items)->
    items.filter ->
      has_value($(this).attr('value'))

  filtered_children: (target_e, items, filter_datas)->
    filters = filter_datas.map (e)->
      e.to_filter()
    filter_opt = transform_linkopt(target_e.dataset.linkageOpt)
    if filter_opt == ','
      items.filter(filters.join(filter_opt))
    else
      filters.reduce (es, filter)->
        es.filter(filter)
      , items
  keep_children: (target_e, items)->
    items.filter(target_e.dataset.linkageKeep)

  selected: (target_e)->
    $(target_e).find('option:selected')

  #return js array
  selected_value: (jitems, linkage)->
    jitems.map ->
      [[(linkage.prefix||'') + $(this).attr(linkage.attr||'value')]]
    .get()

  change: 'change'
}

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rails-linkage.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
