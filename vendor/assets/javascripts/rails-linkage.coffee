has_value = (str) ->
  str != null && str != undefined && str.trim() != ''

transform_linkopt = (opt)->
  if opt != null && opt != undefined && opt.trim().toLowerCase() == 'or'
    ','
  else
    ''

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

hide_and_show = (target_context, target, linkages)->
  target_context.all_children(target, target_context.children(target)).hide()

  filter_datas = $(linkages).get().map (linkage)->
    values = get_context linkage.trigger, trigger_contexts, (trigger_context)->
      trigger_context.selected_value(trigger_context.selected(linkage.trigger), linkage)

    if has_value(linkage.matcher)
      new AttributeMatcher (linkage.matcher||'value'), values, linkage.opt
    else
      new ClassMatcher values, linkage.opt

  (window[target.dataset.linkageCombination]||target_context.filtered_children)(target, target_context.children(target), filter_datas).show()

process_each = (target_context, target)->
  linkages = JSON.parse(target.dataset.linkage)
  if !Array.isArray(linkages)
    linkages = [linkages]

  hide_and_show(target_context, target, linkages)

  linkages.forEach (linkage)->
    if(!linkage.trigger)
      console.error('Miss attribute trigger')
      console.error(linkage)

    get_context linkage.trigger, trigger_contexts, (trigger_context)->
      $(linkage.trigger).on trigger_context.change, ()->
        hide_and_show(target_context, target, linkages)

$(document).on 'bind.linkage', ()->
  $('*[data-linkage]').get().forEach (target)->
    get_context target, target_contexts, (target_context)->
      if(target_context.load)
        $(target).on target_context.load, ()->
          process_each(target_context, target)
      else
        process_each(target_context, target)

$(document).ready ->
  $(document).trigger('bind.linkage')

target_contexts = []
trigger_contexts = []

get_context = (selector, contexts, and_then)->
  $(contexts).filter ()->
    $(selector).is(this.selector)
  .first().map ->
    and_then this
  .get()[0]

default_target_context = ()->
  {
    filtered_children: (selector, items, filter_datas)->
      filters = filter_datas.map (e)->
        e.to_filter()
      filter_opt = transform_linkopt(selector.dataset.linkageOpt)
      if filter_opt == ','
        items.filter(filters.join(filter_opt))
      else
        filters.reduce (es, filter)->
          es.filter(filter)
        , items
  }

default_trigger_context = ()->
  {
    change: 'change'
  }

regist_target_context = (obj...)->
  context = Object.assign(default_target_context(), obj...)
  target_contexts.push(context)
  context

regist_trigger_context = (obj...)->
  context = Object.assign(default_trigger_context(), obj...)
  trigger_contexts.push(context)
  context

regist_context = (obj...)->
  context = Object.assign(default_target_context(), Object.assign(default_trigger_context(), obj...))
  target_contexts.push(context)
  trigger_contexts.push(context)
  context

select = regist_context({
  name: 'select'
  selector: 'select:not(.selectpicker)'

  children: (selector)->
    $(selector).find('option')

  all_children: (selector, items)->
    items.filter ->
      has_value($(this).attr('value'))

  selected: (selector)->
    $(selector).find('option:selected')

  selected_value: (jarray, linkage)->
    jarray.map ->
      [[(linkage.prefix||'') + $(this).attr(linkage.attr||'value')]]
    .get()
})

map_select_options_to_boot_select = (target, options)->
  li_options = $(target.parentElement).find('li')
  options.map ->
    li_options[$(this).index()]

select_bs = regist_context(select, {
  name: 'select_bs'
  selector: 'select.selectpicker'
  load: 'loaded.bs.select'

  all_children: (selector, items)->
    map_select_options_to_boot_select(selector, select.all_children(selector, items))

  filtered_children: (selector, items, filter_datas)->
    map_select_options_to_boot_select(selector, select.filtered_children(selector, items, filter_datas))
})

