has_value = (str) ->
  str != null && str != undefined && str.trim() != ''

transform_linkopt = (opt)->
  if opt != null && opt != undefined && opt.trim().toLowerCase() == 'or'
    ','
  else
    ''

class ClassMatcher
  constructor: (@trigger, @values, @opt)->
  values: ->
    @values
  opt: ->
    @opt
  to_filter: ->
    @values.map (e)->
      '.'+e
    .join(transform_linkopt(@opt))
  trigger: ->
    @trigger

class AttributeMatcher
  constructor: (@trigger, @matcher, @values, @opt)->
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
  trigger: ->
    @trigger

class TextMatcher
  constructor: (@trigger, @values, @opt)->
  opt: ->
    @opt
  values: ->
    @values
  to_filter: ->
    values = @values
    opt = @opt
    ()->
      jitem = $(this)
      res = if transform_linkopt(opt) == ','
        values.reduce (value, text)->
          value || jitem.text() == text
        , false
      else
        values.reduce (value, text)->
          value && jitem.text() == text
        , true
      res

  trigger: ->
    @trigger

hide_and_show = (target_context, target_e, linkage_args)->
  target_context.all_children(target_e, linkage_args, target_context.children(target_e, linkage_args)).hide()

  filter_datas = $(linkage_args.triggers).get().map (linkage)->
    values = get_context linkage.selector, trigger_contexts, (trigger_context)->
      trigger_context.selected_value(trigger_context.selected(linkage.selector).filter(linkage.condition||'*'), linkage)
    if values.length>0
      if has_value(linkage.matcher)
        if linkage.matcher.toLowerCase() == 'text'
          new TextMatcher linkage.selector, values, (linkage.opt||'or')
        else
          new AttributeMatcher linkage.selector, (linkage.matcher||'value'), values, (linkage.opt||'or')
      else
        new ClassMatcher linkage.selector, values, (linkage.opt||'or')
  .filter (e)->
    e

  if filter_datas.length>0
    (window[linkage_args.combination]||target_context.filtered_children)(target_e, linkage_args, target_context.children(target_e, linkage_args), filter_datas).show()
    target_context.keep_children(target_e, linkage_args, target_context.children(target_e, linkage_args)).show()

process_each = (target_context, target_e)->
  linkage_args = JSON.parse(target_e.dataset.linkage)
  if !Array.isArray(linkage_args.triggers)
    linkage_args.triggers = [linkage_args.triggers]

  hide_and_show(target_context, target_e, linkage_args)

  linkage_args.triggers.forEach (linkage)->
    if(!linkage.selector)
      console.error('Miss attribute selector')
      console.error(linkage)

    get_context linkage.selector, trigger_contexts, (trigger_context)->
      $(linkage.selector).on trigger_context.change, ()->
        hide_and_show(target_context, target_e, linkage_args)

$(document).on 'bind.linkage', (event, target_e)->
  if(target_e)
    get_context target_e, target_contexts, (target_context)->
      if(target_context.load)
        $(target_e).on target_context.load, ()->
          process_each(target_context, target_e)
      else
        process_each(target_context, target_e)
  else
    $('*[data-linkage]').get().forEach (target_e)->
      get_context target_e, target_contexts, (target_context)->
        if(target_context.load)
          $(target_e).on target_context.load, ()->
            process_each(target_context, target_e)
        else
          process_each(target_context, target_e)

$(document).ready ->
  $(document).trigger('bind.linkage')

target_contexts = []
trigger_contexts = []

get_context = (selector, contexts, and_then)->
  context = $(contexts).filter ()->
    $(selector).is(this.selector)
  .get()[0]
  if context
    and_then context

default_target_context = ()->
  {
    all_children: (target_e, linkage_args, jitems)->
      jitems.filter(linkage_args.all_children || '*')

    filtered_children: (selector, linkage_args, jitems, filter_datas)->
      filters = filter_datas.map (e)->
        e.to_filter()
      if transform_linkopt(linkage_args.opt) == ','
        jitems.filter ->
          jitem = $(this)
          filters.reduce (value, filter)->
            value || jitem.is(filter)
          , false
      else
        filters.reduce (es, filter)->
          es.filter(filter)
        , jitems

    keep_children: (selector, linkage_args, jitems)->
      jitems.filter(linkage_args.keep)
  }

default_trigger_context = ()->
  {
    change: 'change'
  }

window.regist_target_context = (obj...)->
  context = Object.assign(default_target_context(), obj...)
  target_contexts.unshift(context)
  context

window.regist_trigger_context = (obj...)->
  context = Object.assign(default_trigger_context(), obj...)
  trigger_contexts.unshift(context)
  context

window.regist_context = (obj...)->
  context = Object.assign(default_target_context(), Object.assign(default_trigger_context(), obj...))
  target_contexts.unshift(context)
  trigger_contexts.unshift(context)
  context

default_context = regist_context({
  name: 'default'
  selector: '*'
  children: (target_e, linkage_args)->
    if linkage_args.children
      $(target_e).find(linkage_args.children)
    else
      console.error('Miss attribute data-linkage-children')
      console.error(target_e)
})

select = regist_context({
  name: 'select'
  selector: 'select:not(.selectpicker)'

  children: (target_e, linkage_args)->
    $(target_e).find(linkage_args.children || 'option')

  all_children: (target_e, linkage_args, jitems)->
    jitems.filter(linkage_args.all_children || ':not([value=""])')

  selected: (target_e)->
    $(target_e).find('option:selected')

  selected_value: (jitems, linkage)->
    jitems.map ->
      (linkage.prefix||'') + $(this).attr(linkage.attr||'value')
    .get()
})

map_select_options_to_boot_select = (target_e, options)->
  li_options = $(target_e.parentElement).find('li')
  options.map ->
    li_options[$(this).index()]

select_bs = regist_context(select, {
  name: 'select_bs'
  selector: 'select.selectpicker'
  load: 'loaded.bs.select'

  all_children: (target_e, linkage_args, jitems)->
    map_select_options_to_boot_select(target_e, select.all_children(target_e, linkage_args, jitems))

  filtered_children: (target_e, linkage_args, jitems, filter_datas)->
    map_select_options_to_boot_select(target_e, select.filtered_children(target_e, linkage_args, jitems, filter_datas))

  keep_children: (target_e, linkage_args, jitems)->
    map_select_options_to_boot_select(target_e, select.keep_children(target_e, linkage_args, jitems))
})

table_in_rows = regist_target_context({
  name: 'table_in_rows'
  selector: '.table-linkage-rows'

  children: (target_e, linkage_args)->
    if linkage_args.children
      $(target_e).find(linkage.children)
    else
      if $(target_e).is('tbody')
        $(target_e).find('tr')
      else
        trs = $(target_e).find('tbody > tr')
        if trs.length==0
          $(target_e).find('tr').slice(1)
        else
          trs
})

#headers cells
target_all_headers = (target_e, linkage_args)->
  if linkage_args.headers
    $(target_e).find(linkage_args.headers)
  else
    $(target_e).find('tr').first().find('th,td')

target_all_cells = (target_e, linkage_args)->
  if linkage_args.cells
    $(target_e).find(linkage_args.cells)
  else
    if $(target_e).find('tbody').length
      $(target_e).find('tbody td')
    else
      $(target_e).find('tr').slice(1).find('td')

table_in_cols = regist_target_context({
  name: 'table_in_cols'
  selector: '.table-linkage-cols'

  children: (target_e, linkage_args)->
    target_all_headers(target_e, linkage_args).filter(':not(.linkage-ignore)')

  all_children: (target_e, linkage_args, jitems)->
    all_th = target_all_headers(target_e, linkage_args)
    th_indexs = jitems.map ->
      all_th.index this

    th_indexs.get().reduce (jouts, index)->
      $.merge(jouts, target_all_cells(target_e, linkage_args).filter(':nth-child('+(index+1)+')'))
    , jitems

  filtered_children: (target_e, linkage_args, jitems, filter_datas)->
    all_th = target_all_headers(target_e, linkage_args)
    selected_ths = default_target_context().filtered_children(target_e, linkage_args, jitems, filter_datas)
    th_indexs = selected_ths.map ->
      all_th.index this

    th_indexs.get().reduce (jouts, index)->
      $.merge(jouts, target_all_cells(target_e, linkage_args).filter(':nth-child('+(index+1)+')'))
    , selected_ths
})

