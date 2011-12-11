-- Helper Functions

local function resizeCurrentForRange(current, max)
  local oldCurrent = current:GetText()
  current:SetText(tostring(max))
  current:SetWidth(current:GetFullWidth())
  current:SetText(oldCurrent)
end


-- Public Functions

local function SetBorder(self, width, r, g, b, a)
  Library.LibSimpleWidgets.SetBorder(self.current, width, r, g, b, a)
  Library.LibSimpleWidgets.SetBorder(self.dropdown, width, r, g, b, a)
end

local function SetBackgroundColor(self, r, g, b, a)
  self.current:SetBackgroundColor(r, g, b, a)
  self.dropdown:SetBackgroundColor(r, g, b, a)
end

local function GetDefaultHeight(self)
  return self.slider:GetDefaultHeight() - 2
end

local function GetDefaultWidth(self)
  return self.slider:GetDefaultWidth() + self.current:GetWidth()
end

local function GetEnabled(self)
  return self.enabled
end

local function SetEnabled(self, enabled)
  self.enabled = enabled
  if enabled then
    self.current:SetFontColor(1, 1, 1, 1)
    self.slider:SetEnabled(false)
  else
    self.current:SetFontColor(0.5, 0.5, 0.5, 1)
    self.slider:SetEnabled(false)
  end
end

local function GetRange(self)
  return self.slider:GetRange()
end

local function SetRange(self, min, max)
  self.slider:SetRange(min, max)
  resizeCurrentForRange(self.current, max)
end

local function GetPosition(self)
  return self.slider:GetPosition()
end

local function SetPosition(self, position)
  self.slider:SetPosition(position)
  self.current:SetText(tostring(position))
end


-- Constructor Function

function Library.LibSimpleWidgets.Slider(name, parent)
  local widget = UI.CreateFrame("Frame", name, parent)

  widget.enabled = true

  widget.slider = UI.CreateFrame("RiftSlider", widget:GetName().."Slider", widget)
  widget.slider:SetPoint("TOPLEFT", widget, "TOPLEFT", 0, 6)

  widget.current = UI.CreateFrame("Text", widget:GetName().."Current", widget)
  widget.current:SetBackgroundColor(0, 0, 0, 1)
  widget.current:SetPoint("TOPRIGHT", widget, "TOPRIGHT")
  widget.current:SetPoint("BOTTOMRIGHT", widget, "BOTTOMRIGHT")
  widget.current:SetWidth(50)
  Library.LibSimpleWidgets.SetBorder(widget.current, 1, 0.5, 0.5, 0.5, 1)

  widget.slider:SetPoint("BOTTOMRIGHT", widget.current, "BOTTOMLEFT", -10, 0)

  function widget.slider.Event:SliderChange()
    widget.current:SetText(tostring(widget.slider:GetPosition()))
    if widget.Event.SliderChange then
      widget.Event.SliderChange(widget)
    end
  end

  function widget.slider.Event:SliderGrab()
    if widget.Event.SliderGrab then
      widget.Event.SliderGrab(widget)
    end
  end

  function widget.slider.Event:SliderRelease()
    if widget.Event.SliderRelease then
      widget.Event.SliderRelease(widget)
    end
  end

  widget.SetBorder = SetBorder
  widget.SetBackgroundColor = SetBackgroundColor
  widget.GetDefaultHeight = GetDefaultHeight
  widget.GetDefaultWidth = GetDefaultWidth
  widget.GetEnabled = GetEnabled
  widget.SetEnabled = SetEnabled
  widget.GetRange = GetRange
  widget.SetRange = SetRange
  widget.GetPosition = GetPosition
  widget.SetPosition = SetPosition

  Library.LibSimpleWidgets.EventProxy(widget, {"SliderChange","SliderGrab","SliderRelease"})

  local min, max = widget.slider:GetRange()
  resizeCurrentForRange(widget.current, max)

  widget:SetHeight(widget:GetDefaultHeight())
  widget:SetWidth(widget:GetDefaultWidth())

  widget.current:SetText(tostring(widget.slider:GetPosition()))

  return widget
end
