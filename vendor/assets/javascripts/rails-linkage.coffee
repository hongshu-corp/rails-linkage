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

hide_and_show = (target, linkages)->
  options = $(target).find('option').filter ->
    has_value($(this).attr('value'))

  if $(target).hasClass('selectpicker')
    li_options = $(target.parentElement).find('li')
    options = options.map ->
      li_options[$(this).index()]

  options.hide()

  filter_datas = $(linkages).map ->
    value = (this.prefix||'') + $(this.trigger).find('option:selected').attr(this.attr||'value')
    if has_value(this.matcher)
      [[(this.matcher || 'value'), value]]
    else
      [['.' + value]]

  filter = (window[target.dataset.linkageCombination]||combine_filter)(filter_datas.get(), transform_linkopt(target.dataset.linkageOpt))

  options = $(target).find('option').filter(filter)

  if $(target).hasClass('selectpicker')
    options = options.map ->
      li_options[$(this).index()]

  options.show()

process_each_select = (target)->
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

$(document).on 'bind.select.linkage', ()->
  $('select').filter ->
    this.dataset.linkage && !$(this).hasClass('selectpicker')
  .each ->
    process_each_select(this)

  $('select').filter ->
    this.dataset.linkage && $(this).hasClass('selectpicker')
  .on 'loaded.bs.select', (e)->
    process_each_select(this)

$(document).ready ->
  $(document).trigger('bind.select.linkage')

