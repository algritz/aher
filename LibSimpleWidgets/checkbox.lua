-- Public Functions

local function SetBorder(self, width, r, g, b, a)
  Library.LibSimpleWidgets.SetBorder(self, width, r, g, b, a)
end

local function SetBackgroundColor(self, r, g, b, a)
  self:SetBackgroundColor(r, g, b, a)
end

local function GetChecked(self)
  return self.check:GetChecked()
end

local function SetChecked(self, checked)
  self.check:SetChecked(checked)
end

local function GetEnabled(self)
  return self.check:GetEnabled()
end

local function SetEnabled(self, enabled)
  self.check:SetEnabled(enabled)
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
    self.check:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 1)
    self.label:SetPoint("TOPLEFT", self, "TOPLEFT", self.check:GetWidth(), 0)
    self.label:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT")
  elseif pos == "left" then
    self.check:ClearAll()
    self.label:ClearAll()
    self.check:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 1)
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


-- Constructor Function

function Library.LibSimpleWidgets.Checkbox(name, parent)
  local widget = UI.CreateFrame("Frame", name, parent)

  local check = UI.CreateFrame("RiftCheckbox", name.."Check", widget)
  widget.check = check

  local label = UI.CreateFrame("Text", name.."Label", widget)
  widget.label = label

  label:SetPoint("TOPLEFT", widget, "TOPLEFT", check:GetWidth(), 0)
  label:SetPoint("BOTTOMRIGHT", widget, "BOTTOMRIGHT")

  check:SetPoint("CENTERRIGHT", label, "CENTERLEFT")

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

  label.Event.MouseIn = MouseIn
  label.Event.MouseOut = MouseOut
  label.Event.MouseMove = MouseMove
  function label.Event:LeftClick()
    check:SetChecked(not check:GetChecked())
  end

  check.Event.MouseIn = MouseIn
  check.Event.MouseOut = MouseOut
  check.Event.MouseMove = MouseMove
  function check.Event:CheckboxChange()
    if widget.Event.CheckboxChange then
      widget.Event.CheckboxChange(widget)
    end
  end

  widget:SetHeight(label:GetFullHeight())
  widget:SetWidth(check:GetWidth() + label:GetFullWidth())

  widget.SetBorder = SetBorder
  widget.SetBackgroundColor = SetBackgroundColor
  widget.GetFontSize = GetFontSize
  widget.SetFontSize = SetFontSize
  widget.GetChecked = GetChecked
  widget.SetChecked = SetChecked
  widget.GetEnabled = GetEnabled
  widget.SetEnabled = SetEnabled
  widget.GetText = GetText
  widget.SetText = SetText
  widget.SetLabelPos = SetLabelPos

  Library.LibSimpleWidgets.EventProxy(widget, {"CheckboxChange", "MouseIn", "MouseOut", "MouseMove"})

  return widget
end
