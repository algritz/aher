-- Public Functions

local function GetTexture(selected, enabled)
  if selected and enabled then
    return "textures/radiobutton_selected.png"
  elseif selected and not enabled then
    return "textures/radiobutton_selected_disabled.png"
  elseif not selected and enabled then
    return "textures/radiobutton.png"
  elseif not selected and not enabled then
    return "textures/radiobutton_disabled.png"
  end
end

local function SetBorder(self, width, r, g, b, a)
  Library.LibSimpleWidgets.SetBorder(self, width, r, g, b, a)
end

local function SetBackgroundColor(self, r, g, b, a)
  self:SetBackgroundColor(r, g, b, a)
end

local function GetSelected(self)
  return self.check.checked
end

local function SetSelected(self, selected)
  self.check.checked = selected
  self.check:SetTexture("LibSimpleWidgets", GetTexture(self.check.checked, self.enabled))
  if selected and self.Event.RadioButtonSelect then
    self.Event.RadioButtonSelect(self)
  end
end

local function GetEnabled(self)
  return self.enabled
end

local function SetEnabled(self, enabled)
  self.enabled = enabled
  self.check:SetTexture("LibSimpleWidgets", GetTexture(self.check.checked, self.enabled))
  if enabled then
    self.label:SetFontColor(1, 1, 1, 1)
  else
    self.label:SetFontColor(0.5, 0.5, 0.5, 1)
  end
end

local function GetText(self)
  return self.label:GetText()
end

local function SetText(self, text)
  self.label:SetText(text)
  self:SetHeight(self.label:GetFullHeight())
  self:SetWidth(self.check:GetWidth() + self.label:GetFullWidth())
end

local function SetLabelPos(self, pos)
  if pos == "right" then
    self.check:ClearAll()
    self.label:ClearAll()
    self.check:SetPoint("CENTERRIGHT", self.label, "CENTERLEFT")
    self.label:SetPoint("TOPLEFT", self, "TOPLEFT", self.check:GetWidth(), 0)
    self.label:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT")
  elseif pos == "left" then
    self.check:ClearAll()
    self.label:ClearAll()
    self.check:SetPoint("CENTERLEFT", self.label, "CENTERRIGHT")
    self.label:SetPoint("TOPRIGHT", self, "TOPRIGHT", -self.check:GetWidth(), 0)
    self.label:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT")
  end
end

local function GetFontSize(self)
  return self.label:GetFontSize()
end

local function SetFontSize(self, size)
  self.label:SetFontSize(size)
  self:SetHeight(self.label:GetFullHeight())
  self:SetWidth(self.check:GetWidth() + self.label:GetFullWidth())
end

local function GetFontColor(self)
  return self.label:GetFontColor()
end

local function SetFontColor(self, r, g, b, a)
  self.label:SetFontColor(r, g, b, a)
end


-- Constructor Function

function Library.LibSimpleWidgets.RadioButton(name, parent)
  local widget = UI.CreateFrame("Frame", name, parent)

  widget.enabled = true

  local check = UI.CreateFrame("Texture", name.."Check", widget)
  check:SetTexture("LibSimpleWidgets", GetTexture(false, true))
  check.checked = false
  widget.check = check

  local label = UI.CreateFrame("Text", name.."Label", widget)
  widget.label = label

  label:SetPoint("TOPLEFT", widget, "TOPLEFT", check:GetWidth(), 0)
  label:SetPoint("BOTTOMRIGHT", widget, "BOTTOMRIGHT")

  --check:SetPoint("CENTERRIGHT", label, "CENTERLEFT")

  local function MouseIn(self)
    if widget.Event.MouseIn and not (widget.label.mousein or widget.label.mousein) then
      self.mousein = true
      widget.Event.MouseIn(widget)
    end
  end
  local function MouseOut(self)
    self.mousein = false
    if widget.Event.MouseOut and not (widget.label.mousein or widget.label.mousein) then
      widget.Event.MouseOut(widget)
    end
  end
  local function MouseMove(self)
    if widget.Event.MouseMove then
      widget.Event.MouseMove(widget)
    end
  end
  local function LeftClick(self)
    if not check.checked and widget.enabled then
      widget:SetSelected(true)
    end
  end

  label.Event.MouseIn = MouseIn
  label.Event.MouseOut = MouseOut
  label.Event.MouseMove = MouseMove
  label.Event.LeftClick = LeftClick

  check.Event.MouseIn = MouseIn
  check.Event.MouseOut = MouseOut
  check.Event.MouseMove = MouseMove
  check.Event.LeftClick = LeftClick

  widget:SetHeight(label:GetFullHeight())
  widget:SetWidth(check:GetWidth() + label:GetFullWidth())

  widget.SetBorder = SetBorder
  widget.SetBackgroundColor = SetBackgroundColor
  widget.GetFontSize = GetFontSize
  widget.SetFontSize = SetFontSize
  widget.GetFontColor = GetFontColor
  widget.SetFontColor = SetFontColor
  widget.GetSelected = GetSelected
  widget.SetSelected = SetSelected
  widget.GetEnabled = GetEnabled
  widget.SetEnabled = SetEnabled
  widget.GetText = GetText
  widget.SetText = SetText
  widget.SetLabelPos = SetLabelPos

  widget:SetLabelPos("right")

  Library.LibSimpleWidgets.EventProxy(widget, {"RadioButtonSelect", "MouseIn", "MouseOut", "MouseMove"})

  return widget
end
