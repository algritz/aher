-- Internal Functions

local function ContentResized(self)
  local maxOffset = self:GetMaxOffset()
  if maxOffset == 0 then
    self.scrollbar:SetVisible(false)
    self.offset = 0
  else
    if self.offset > maxOffset then
      self.offset = maxOffset
    end
    self.scrollbar:SetRange(0, maxOffset)
    self.scrollbar:SetThickness(self:GetHeight() / self.content:GetHeight() * maxOffset)
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
  return math.max(0, self.content:GetHeight() - self:GetHeight())
end

local function PositionContent(self)
  self.content:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -self.offset)
  self.content:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, -self.offset)
end

local function PositionScrollbar(self)
  if self.scrollbar:GetVisible() then
    self.scrollbar:SetPosition(self.offset)
  end
end


-- Event Functions

local function WheelForward(self)
  if not self.content then
    return
  end

  if self.content:GetHeight() < self:GetHeight() then
    return
  end

  self.offset = math.max(0, self.offset - self.scrollInterval)

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

  local _, maxOffset = self.scrollbar:GetRange()
  self.offset = math.min(maxOffset, self.offset + self.scrollInterval)

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

  local height = content:GetHeight()
  content:ClearAll()
  content:SetHeight(height)

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

local function GetScrollbarWidth(self)
  return self.scrollbar:GetWidth()
end

local function SetScrollbarWidth(self, width)
  self.scrollbar:SetWidth(width)
end


-- Constructor Functions

local function CreateScrollbar(scrollview)
  local scrollbar = UI.CreateFrame("RiftScrollbar", scrollview:GetName().."Scrollbar", scrollview:GetParent())
  scrollbar.scrollview = scrollview
  scrollbar:SetOrientation("vertical")
  scrollbar:SetLayer(10)
--  scrollbar:SetWidth(10)
  scrollbar:SetPoint("TOPRIGHT", scrollview, "TOPRIGHT", 0, 0)
  scrollbar:SetPoint("BOTTOMRIGHT", scrollview, "BOTTOMRIGHT", 0, 0)
  scrollbar:SetVisible(false)
  scrollbar.Event.ScrollbarChange = function()
    scrollview.offset = scrollbar:GetPosition()
    scrollview:PositionContent()
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
  widget.GetScrollbarWidth = GetScrollbarWidth
  widget.SetScrollbarWidth = SetScrollbarWidth

  -- Helper Functions
  widget.ContentResized = ContentResized
  widget.GetScrollOffset = GetScrollOffset
  widget.ScrollTo = ScrollTo
  widget.GetMaxOffset = GetMaxOffset
  widget.PositionContent = PositionContent
  widget.PositionScrollbar = PositionScrollbar

  -- Events
  widget.Event.WheelBack = WheelBack
  widget.Event.WheelForward = WheelForward

  return widget
end
