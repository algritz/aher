local LINE_HEIGHT = 12.65
local PADDING = 4

local env16 = Inspect.System.Secure ~= nil

-- Helper Functions

local function countLines(text)
  local count = 1
  for n in text:gmatch("[\r\n]") do
    count = count + 1
  end
  return count
end

local function resizeToText(frame, text)
  local lineCount = countLines(text)
  local height = LINE_HEIGHT * lineCount + PADDING*2
  frame:SetHeight(height)
end


-- Hook Functions

local function SetTextHook(self, text)
  self:OldSetText(text)
  resizeToText(self, text)
end


-- Textfield Frame Events

local function KeyUpHandler(self, key)
  local widget = self:GetParent():GetParent()

  -- Handle Enter and Tab
  local code = string.byte(key)
  local text = self:GetText()
  local pos = self:GetCursor()
  local prefix = string.sub(text, 1, pos)
  local suffix = string.sub(text, pos+1)
  if tonumber(code) == 13 then
    local newText = prefix .."\n".. suffix
    resizeToText(self, newText)
    self:OldSetText(newText)
    if env16 then
      self:SetCursor(pos+1) -- Rift 1.6
    else
      self:SetSelection(pos, pos+1)
    end
    if widget.Event.TextAreaChange then
      widget.Event.TextAreaChange(widget)
    end
  elseif tonumber(code) == 9 then
    if env16 then
      local newText = prefix .."\t".. suffix
      resizeToText(self, newText)
      self:OldSetText(newText)
      self:SetCursor(pos+1) -- Rift 1.6
    else
      local newText = prefix .."\t ".. suffix
      resizeToText(self, newText)
      self:OldSetText(newText)
      self:SetSelection(pos+1, pos+2)
    end
    if widget.Event.TextAreaChange then
      widget.Event.TextAreaChange(widget)
    end
  end

  -- calc cursor offset, ensure it's visible
  local text = self:GetText()
  local pos = self:GetCursor()
  local prefix = string.sub(text, 1, pos)
  local cursorLine = countLines(prefix)
  local scroller = self:GetParent()
  local cursorOffset = (cursorLine-1) * LINE_HEIGHT + PADDING
  if cursorOffset < scroller:GetScrollOffset() then
    scroller:ScrollTo(math.max(cursorOffset, 0))
  elseif cursorOffset > scroller:GetScrollOffset() + scroller:GetHeight() - LINE_HEIGHT then
    scroller:ScrollTo(math.min(cursorOffset - scroller:GetHeight() + LINE_HEIGHT + PADDING, scroller:GetMaxOffset()))
  end
end

local function TextfieldChangeHandler(self)
  local scroller = self:GetParent()
  local widget = scroller:GetParent()
  if widget.Event.TextAreaChange then
    widget.Event.TextAreaChange(widget)
  end
  resizeToText(self, self:GetText())
end

local function TextfieldSelectHandler(self)
  local scroller = self:GetParent()
  local widget = scroller:GetParent()
  if widget.Event.TextAreaSelect then
    widget.Event.TextAreaSelect(widget)
  end
end


-- Public Functions

local function SetBorder(self, width, r, g, b, a)
  Library.LibSimpleWidgets.SetBorder(self.scroller, width, r, g, b, a)
end

local function SetBackgroundColor(self, r, g, b, a)
  self.scroller:SetBackgroundColor(r, g, b, a)
end

local function GetText(self)
  return self.textarea:GetText()
end

local function SetText(self, ...)
  self.textarea:SetText(...)
end

local function GetCursor(self)
  return self.textarea:GetCursor()
end

local function SetCursor(self, ...)
  self.textarea:SetCursor(...)
end

local function GetEnabled(self)
  return self.enabled
end

local function SetEnabled(self, enabled)
  self.enabled = enabled
  self.blocker:SetVisible(not enabled)
end

local function GetSelection(self)
  return self.textarea:GetSelection()
end

local function SetSelection(self, ...)
  self.textarea:SetSelection(...)
end

local function GetSelectionText(self)
  self.textarea:GetSelectionText()
end

local function GetKeyFocus(self)
  return self.textarea:GetKeyFocus()
end

local function SetKeyFocus(self, ...)
  self.textarea:SetKeyFocus(...)
end


-- Constructor Function

function Library.LibSimpleWidgets.TextArea(name, parent)
  local widget = UI.CreateFrame("Frame", name, parent)
  local scroller = UI.CreateFrame("SimpleScrollView", name.."ScrollView", widget)
  scroller:SetAllPoints(widget)
  local textarea = UI.CreateFrame("RiftTextfield", name.."TextArea", scroller)
  scroller:SetContent(textarea)
  local blocker = UI.CreateFrame("Frame", name.."Blocker", parent)
  blocker:SetAllPoints(widget)
  blocker:SetBackgroundColor(0, 0, 0, 0.5)
  blocker:SetLayer(widget:GetLayer()+1)
  blocker:SetVisible(false)

  -- Dummy blocking events
  blocker.Event.LeftDown = function() end
  blocker.Event.LeftUp = function() end
  blocker.Event.LeftClick = function() end
  blocker.Event.WheelForward = function() end
  blocker.Event.WheelBack = function() end

  widget.scroller = scroller
  widget.textarea = textarea
  widget.blocker = blocker

  widget.enabled = true

  -- Install SetText hook on the textarea to handle resizing
  textarea.OldSetText = textarea.SetText
  textarea.SetText = SetTextHook

  textarea.Event.KeyUp = KeyUpHandler
  textarea.Event.TextfieldChange = TextfieldChangeHandler
  textarea.Event.TextfieldSelect = TextfieldSelectHandler

  widget.SetBorder = SetBorder
  widget.SetBackgroundColor = SetBackgroundColor
  widget.GetCursor = GetCursor
  widget.SetCursor = SetCursor
  widget.GetEnabled = GetEnabled
  widget.SetEnabled = SetEnabled
  widget.GetSelection = GetSelection
  widget.SetSelection = SetSelection
  widget.GetSelectionText = GetSelectionText
  widget.GetText = GetText
  widget.SetText = SetText
  widget.GetKeyFocus = GetKeyFocus
  widget.SetKeyFocus = SetKeyFocus

  Library.LibSimpleWidgets.EventProxy(widget, {"TextAreaChange","TextAreaSelect"})

  return widget
end
