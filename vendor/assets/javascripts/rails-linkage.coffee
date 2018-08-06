has_value = (str) ->
  str != null && str != undefined && str.trim() != ''

transform_linkopt = (opt)->
  if opt != null && opt != undefined && opt.trim().toLowerCase() == 'or'
    ','
  else
    ''

combine_filter = (elements, filter_datas, opt)->
  filters = filter_datas.map (e)->
    e.to_filter()
  filter_opt = transform_linkopt(opt)
  if filter_opt == ','
    elements.filter(filters.join(filter_opt))
  else
    filters.reduce (elements, filter)->
      elements.filter(filter)
    , elements

map_select_options_to_boot_select = (target, options)->
  li_options = $(target.parentElement).find('li')
  options.map ->
    li_options[$(this).index()]

all_items = {
  select: (target)->
    options = $(target).find('option').filter ->
      has_value($(this).attr('value'))
    if $(target).hasClass('selectpicker')
      options = map_select_options_to_boot_select(target, options)
    options
}

trigger_values = {
  select: (linkage)->
    [(linkage.prefix||'') + $(linkage.trigger).find('option:selected').attr(linkage.attr||'value')]
}

filtered_items = {
  select: (target, filter, filter_datas)->
    options = filter($(target).find('option'), filter_datas, target.dataset.linkageOpt)
    if $(target).hasClass('selectpicker')
      options = map_select_options_to_boot_select(target, options)
    options
}

class ClassMatcher
  constructor: (@values, @opt)->
  values: ->
    @values
  opt: ->
    @opt
  to_filter: ->
    @values.map (e)->
      '.'+e
    .join(transform_linkopt(@opt))

class AttributeMatcher
  constructor: (@matcher, @values, @opt)->
  matcher: ->
    @matcher
  values: ->
    @values
  opt: ->
    @opt
  to_filter: ->
    m = @matcher
    @values.map (e)->
      "[#{m}=#{e}]"
    .join(transform_linkopt(@opt))

hide_and_show = (target, linkages)->
  all_items[target.nodeName.toLowerCase()](target).hide()
  filter_datas = $(linkages).map ->
    values = trigger_values[$(this.trigger)[0].nodeName.toLowerCase()](this)
    if has_value(this.matcher)
      new AttributeMatcher (this.matcher||'value'), values, this.opt
    else
      new ClassMatcher values, this.opt
  filtered_items[target.nodeName.toLowerCase()](target, combine_filter, filter_datas.get()).show()

process_each = (target)->
  linkages = JSON.parse(target.dataset.linkage)
  if !Array.isArray(linkages)
    linkages = [linkages]

  hide_and_show(target, linkages)

  linkages.forEach (linkage)->
    if(!linkage.trigger)
      console.error('Miss attribute trigger')
      console.error(linkage)

    $(linkage.trigger).change ->
      hide_and_show(target, linkages)

$(document).on 'bind.linkage', ()->
  $('*[data-linkage]').filter ->
    !$(this).hasClass('selectpicker')
  .each ->
    process_each(this)

  $('*[data-linkage]').filter ->
    $(this).hasClass('selectpicker')
  .on 'loaded.bs.select', (e)->
    process_each(this)

$(document).ready ->
  $(document).trigger('bind.linkage')

