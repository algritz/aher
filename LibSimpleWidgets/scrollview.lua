-- Internal Functions

local function ContentResized(self)
  if self.content:GetHeight() < self:GetHeight() then
    self.scrollbar:SetVisible(false)
    self.offset = 0
  else
    local maxOffset = self:GetMaxOffset()
    if self.offset > maxOffset then
      self.offset = maxOffset
    end
    self.scrollbar:SetHeight(self:GetHeight() / self.content:GetHeight() * self:GetHeight())
    self.scrollbar:SetVisible(self.showScrollbar)
  end
  self:PositionContent()
  self:PositionScrollbar()
end

local function GetScrollOffset(self)
  return self.offset
end

local function ScrollTo(self, offset)
  self.offset = offset
  self:PositionContent()
  self:PositionScrollbar()
end

local function GetMaxOffset(self)
  return self.content:GetHeight() - self:GetHeight()
end

local function GetOffsetForScrollbarY(self, y)
  return y / self:GetHeight() * self.content:GetHeight()
end

local function PositionContent(self)
  self.content:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -self.offset)
  self.content:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, -self.offset)
end

local function PositionScrollbar(self)
  local scrollbarOffset = self.offset / self.content:GetHeight() * self:GetHeight()
  self.scrollbar:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, scrollbarOffset)
end


-- Event Functions

local function WheelForward(self)
  if not self.content then
    return
  end

  if self.content:GetHeight() < self:GetHeight() then
    return
  end

  if self.offset >= self.scrollInterval then
    self.offset = self.offset - self.scrollInterval
  else
    self.offset = 0
  end

  self:PositionContent()
  self:PositionScrollbar()
end

local function WheelBack(self)
  if not self.content then
    return
  end

  if self.content:GetHeight() < self:GetHeight() then
    return
  end

  local maxOffset = self:GetMaxOffset()
  if self.offset <= maxOffset - self.scrollInterval then
    self.offset = self.offset + self.scrollInterval
  else
    self.offset = maxOffset
  end

  self:PositionContent()
  self:PositionScrollbar()
end

local function ContentSizeChanged(self)
  self:GetParent():ContentResized()
  if self:GetParent().oldContentSizeFunc then
    self:GetParent():oldContentSizeFunc()
  end
end


-- Public Functions

local function SetBorder(self, width, r, g, b, a)
  Library.LibSimpleWidgets.SetBorder(self, width, r, g, b, a)
end

local function SetBackgroundColor(self, r, g, b, a)
  self.bg:SetBackgroundColor(r, g, b, a)
end

local function SetContent(self, content)
  if self.content then
    self.content:SetVisible(false)
    self.content.Event.Size = self.oldContentSizeFunc
    self.oldContentSizeFunc = nil
    self.content = nil
  end

  self.content = content
  self.offset = 0

  content:SetParent(self)
  content:SetLayer(5)

  self.oldContentSizeFunc = content.Event.Size
  content.Event.Size = ContentSizeChanged

  self:ContentResized()
end

local function GetScrollInterval(self)
  return self.scrollInterval
end

local function SetScrollInterval(self, interval)
  self.scrollInterval = interval
end

local function GetShowScrollbar(self)
  return self.showScrollbar
end

local function SetShowScrollbar(self, show)
  self.showScrollbar = show
  self.scrollbar:SetVisible(show)
end

local function GetScrollbarColor(self)
  return self.scrollbar:GetBackgroundColor()
end

local function SetScrollbarColor(self, r, g, b, a)
  self.scrollbar:SetBackgroundColor(r, g, b, a)
end

local function GetScrollbarWidth(self)
  return self.scrollbar:GetWidth()
end

local function SetScrollbarWidth(self, width)
  self.scrollbar:SetWidth(width)
end


-- Constructor Functions

local function CreateScrollbar(scrollview)
  local scrollbar = UI.CreateFrame("Frame", scrollview:GetName().."Scrollbar", scrollview:GetParent())
  scrollbar.scrollview = scrollview
  scrollbar:SetLayer(10)
  scrollbar:SetWidth(10)
  scrollbar:SetBackgroundColor(1, 1, 1, 0.5)
  scrollbar:SetPoint("TOPRIGHT", scrollview, "TOPRIGHT", 0, 0)
  scrollbar:SetVisible(false)
  scrollbar.leftDown = false
  function scrollbar.Event:LeftDown()
    self.leftDown = true
    self.originalYDiff = Inspect.Mouse().y - self:GetTop()
  end
  function scrollbar.Event:LeftUp()
    self.leftDown = false
  end
  function scrollbar.Event:LeftUpoutside()
    self.leftDown = false
  end
  function scrollbar.Event:MouseMove(x, y)
    if not self.leftDown then
      return
    end

    local widget = self.scrollview

    local relY = y - widget:GetTop()
    local newScrollY = relY - self.originalYDiff
    widget.offset = math.min(widget:GetMaxOffset(), math.max(0, widget:GetOffsetForScrollbarY(newScrollY)))

    widget:PositionContent()
    widget:PositionScrollbar()
  end
  return scrollbar
end

function Library.LibSimpleWidgets.ScrollView(name, parent)
  local widget = UI.CreateFrame("Mask", name, parent)

  widget.scrollInterval = 35
  widget.showScrollbar = true

  widget.bg = UI.CreateFrame("Frame", widget:GetName().."BG", widget)
  widget.bg:SetAllPoints(widget)
  widget.bg:SetLayer(-1)
  widget.bg:SetBackgroundColor(0, 0, 0, 0)

  widget.scrollbar = CreateScrollbar(widget)

  -- Public API
  widget.SetBorder = SetBorder
  widget.SetBackgroundColor = SetBackgroundColor
  widget.SetContent = SetContent
  widget.GetScrollInterval = GetScrollInterval
  widget.SetScrollInterval = SetScrollInterval
  widget.GetShowScrollbar = GetShowScrollbar
  widget.SetShowScrollbar = SetShowScrollbar
  widget.GetScrollbarColor = GetScrollbarColor
  widget.SetScrollbarColor = SetScrollbarColor
  widget.GetScrollbarWidth = GetScrollbarWidth
  widget.SetScrollbarWidth = SetScrollbarWidth

  -- Helper Functions
  widget.ContentResized = ContentResized
  widget.GetScrollOffset = GetScrollOffset
  widget.ScrollTo = ScrollTo
  widget.GetMaxOffset = GetMaxOffset
  widget.GetOffsetForScrollbarY = GetOffsetForScrollbarY
  widget.PositionContent = PositionContent
  widget.PositionScrollbar = PositionScrollbar

  -- Events
  widget.Event.WheelBack = WheelBack
  widget.Event.WheelForward = WheelForward

  return widget
end
