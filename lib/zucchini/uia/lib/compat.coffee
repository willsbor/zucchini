UIAElement.prototype.$ = (name) ->
  $.debug "element.$ is deprecated. Zucchini now supports mechanic.js selectors: https://github.com/jaykz52/mechanic"
  $('#' + name).first()

waitForElement = (element) ->
  $.debug "waitForElement is deprecated. Please use $.wait(finderFunction)"
  $.wait(-> element)

extend = $.extend
