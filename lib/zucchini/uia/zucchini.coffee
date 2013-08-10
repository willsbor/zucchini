# Run a Zucchini feature
Zucchini = (featureText, orientation) ->
  rotateTo(orientation)

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
      if wait(screen.anchor)
        $.log "Found anchor for screen '#{screenName}'"
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
