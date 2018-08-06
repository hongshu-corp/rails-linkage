has_value = (str) ->
  str != null && str != undefined && str.trim() != ''

combine_filter = (filter_datas, opt)->
  filter_datas.map (e)->
    if e.length == 2
      "[#{e[0]}=#{e[1]}]"
    else
      e[0]
  .join(opt)

transform_linkopt = (opt)->
  if opt != null && opt != undefined && opt.trim().toLowerCase() == 'or'
    ','
  else
    ''

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

filtered_items = {
  select: (target, filter)->
    options = $(target).find('option').filter(filter)
    if $(target).hasClass('selectpicker')
      options = map_select_options_to_boot_select(target, options)
    options
}

hide_and_show = (target, linkages)->
  all_items[target.nodeName.toLowerCase()](target).hide()
  filter_datas = $(linkages).map ->
    value = (this.prefix||'') + $(this.trigger).find('option:selected').attr(this.attr||'value')
    if has_value(this.matcher)
      [[(this.matcher || 'value'), value]]
    else
      [['.' + value]]
  filter = (window[target.dataset.linkageCombination]||combine_filter)(filter_datas.get(), transform_linkopt(target.dataset.linkageOpt))
  filtered_items[target.nodeName.toLowerCase()](target, filter).show()

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
  $('select').filter ->
    this.dataset.linkage && !$(this).hasClass('selectpicker')
  .each ->
    process_each(this)

  $('select').filter ->
    this.dataset.linkage && $(this).hasClass('selectpicker')
  .on 'loaded.bs.select', (e)->
    process_each(this)

$(document).ready ->
  $(document).trigger('bind.linkage')

