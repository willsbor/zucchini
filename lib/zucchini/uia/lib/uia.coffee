# Expose global objects to the user
target = UIATarget.localTarget()
app    = target.frontMostApp()
view   = app.mainWindow()

# Prevent UIA from auto handling alerts
UIATarget.onAlert = (alert) -> return true

# Prepend screenshot names with numbers
screensCount = 0
target.captureScreenWithName_ = target.captureScreenWithName
target.captureScreenWithName = (name) ->
  number = (if (++screensCount < 10) then "0#{screensCount}" else screensCount)
  @captureScreenWithName_ "#{number}_#{name}"
