#
# A heads-up-display (HUD) for showing Vimium page operations.
# Note: you cannot interact with the HUD until document.body is available.
#
HUD =
  _tweenId: -1
  _displayElement: null

  # This HUD is styled to precisely mimick the chrome HUD on Mac. Use the "has_popup_and_link_hud.html"
  # test harness to tweak these styles to match Chrome's. One limitation of our HUD display is that
  # it doesn't sit on top of horizontal scrollbars like Chrome's HUD does.

  showForDuration: (text, duration) ->
    HUD.show(text)
    HUD._showForDurationTimerId = setTimeout((-> HUD.hide()), duration)

  show: (text) ->
    return unless HUD.enabled()
    clearTimeout(HUD._showForDurationTimerId)
    HUD.displayElement().innerText = text
    clearInterval(HUD._tweenId)
    HUD._tweenId = Tween.fade(HUD.displayElement(), 1.0, 150)
    HUD.displayElement().style.display = ""

  #
  # Retrieves the HUD HTML element.
  #
  displayElement: ->
    if (!HUD._displayElement)
      HUD._displayElement = HUD.createHudElement()
      # Keep this far enough to the right so that it doesn't collide with the "popups blocked" chrome HUD.
      HUD._displayElement.style.right = "150px"
    HUD._displayElement

  createHudElement: ->
    element = document.createElement("div")
    element.className = "vimiumReset vimiumHUD"
    document.body.appendChild(element)
    element

  # Hide the HUD.
  # If :immediate is falsy, then the HUD is faded out smoothly (otherwise it is hidden immediately).
  # If :updateIndicator is truthy, then we also refresh the mode indicator.  The only time we don't update the
  # mode indicator, is when hide() is called for the mode indicator itself.
  hide: (immediate = false, updateIndicator = true) ->
    clearInterval(HUD._tweenId)
    if immediate
      HUD.displayElement().style.display = "none" unless updateIndicator
      Mode.setIndicator() if updateIndicator
    else
      HUD._tweenId = Tween.fade HUD.displayElement(), 0, 150, -> HUD.hide true, updateIndicator

  isReady: do ->
    ready = false
    DomUtils.documentReady -> ready = true
    -> ready and document.body != null

  # A preference which can be toggled in the Options page. */
  enabled: -> !settings.get("hideHud")

Tween =
  #
  # Fades an element's alpha. Returns a timer ID which can be used to stop the tween via clearInterval.
  #
  fade: (element, toAlpha, duration, onComplete) ->
    state = {}
    state.duration = duration
    state.startTime = (new Date()).getTime()
    state.from = parseInt(element.style.opacity) || 0
    state.to = toAlpha
    state.onUpdate = (value) ->
      element.style.opacity = value
      if (value == state.to && onComplete)
        onComplete()
    state.timerId = setInterval((-> Tween.performTweenStep(state)), 50)
    state.timerId

  performTweenStep: (state) ->
    elapsed = (new Date()).getTime() - state.startTime
    if (elapsed >= state.duration)
      clearInterval(state.timerId)
      state.onUpdate(state.to)
    else
      value = (elapsed / state.duration)  * (state.to - state.from) + state.from
      state.onUpdate(value)

root = exports ? window
root.HUD = HUD
