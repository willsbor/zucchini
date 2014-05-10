Function::bind = (context) ->
  return this unless context
  fun = this
  -> fun.apply context, arguments

String::camelCase = ->
  @replace /([\-\ ][A-Za-z])/g, ($1) ->
    $1.toUpperCase().replace /[\-\ ]/g, ''

# Instruments >= 4.5 crash when a JS primitive is thrown
# http://apple.stackexchange.com/questions/69484/unknown-xcode-instruments-crash
raise = (message) -> throw new Error(message)

# A finder could return an UIAElement or an array from a mechanic.js selector
# Handle both cases
_elementFrom = (finder) ->
  res = finder()
  res = res[0] if res and typeof res.length is 'number'
  res

# Execute a finder function until the element appears or timeout reached
# The default timeout is 10 seconds if not specified by users
wait = (finder) ->
  wait finder, null

wait = (finder, timeout) ->
  timeout = 10 unless timeout?
  found   = false
  counter = 0
  element = null

  while not found and counter < timeout
    element = _elementFrom finder

    if element? and element.checkIsValid() and element.isVisible()
      found = true
    else
      target.delay 0.5
      counter += 0.5

  if found then element else false

rotateTo = (orientation) ->
  target.setDeviceOrientation(
    if orientation is 'portrait' then UIA_DEVICE_ORIENTATION_PORTRAIT
    else UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT
  )
