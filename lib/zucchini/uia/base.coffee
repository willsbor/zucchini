Function::bind = (context) ->
  return this unless context
  fun = this
  -> fun.apply context, arguments

String::camelCase = ->
  @replace /([\-\ ][A-Za-z])/g, ($1) -> $1.toUpperCase().replace /[\-\ ]/g, ""

extend = $.extend
puts   = (text) -> UIALogger.logMessage text

# Instruments 4.5 crash when a JS primitive is thrown
# http://apple.stackexchange.com/questions/69484/unknown-xcode-instruments-crash
raise = (message) -> throw new Error(message)

# Prevent UIA from auto handling alerts
UIATarget.onAlert = (alert) -> return true

target = UIATarget.localTarget()
app    = target.frontMostApp()
view   = app.mainWindow()

UIAElement.prototype.$ = (name) -> $('#' + name).first()

target.waitForElement = (fn) ->
  found   = false
  counter = 0
  element = null

  while not found and (counter < 10)
    element = $(fn()).first()
    if element.isValid() and element.isVisible()
      found = true
    else
      @delay 0.5
      counter++
  if found then element else false

isNullElement = (elem) -> elem.toString() is "[object UIAElementNil]"

screensCount = 0
target.captureScreenWithName_ = target.captureScreenWithName
target.captureScreenWithName = (screenName) ->
  screensCountText = (if (++screensCount < 10) then "0" + screensCount else screensCount)
  @captureScreenWithName_ screensCountText + "_" + screenName

class Zucchini
  @run: (featureText, initial_orientation) ->
    if initial_orientation == 'portrait'
      target.setDeviceOrientation UIA_DEVICE_ORIENTATION_PORTRAIT
    else if initial_orientation == 'landscape'
      target.setDeviceOrientation UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT

    sections = featureText.trim().split(/\n\s*\n/)

    for section in sections
      lines = section.split(/\n/)

      screenMatch = lines[0].match(/.+ on the "([^"]*)" screen:$/)
      raise "Line '#{lines[0]}' doesn't define a screen context" unless screenMatch

      screenName = screenMatch[1]
      try
        screen = eval("new #{screenName.camelCase()}Screen")
      catch e
        raise "Screen '#{screenName}' not defined"

      if screen.anchor
        if target.waitForElement(screen.anchor)
          puts "Found anchor for screen '#{screenName}'"
        else
          raise "Could not find anchor for screen '#{screenName}'"

      for line in lines.slice(1)
         functionFound = false
         for regExpText, func of screen.actions
            match = line.trim().match(new RegExp(regExpText))
            if match
              functionFound = true
              func.bind(screen)(match[1],match[2])
         raise "Action for line '#{line}' not defined" unless functionFound
