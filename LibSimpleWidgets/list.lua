
-- Item Frame Events

local function ItemClick(self)
  local widget = self:GetParent()
  if not widget.enabled then return end
  local item = self:GetText()
  widget:SetSelectedIndex(self.index)
end

local function ItemMouseIn(self)
  local widget = self:GetParent()
  if not widget.enabled then return end
  if not self.selected then
    self:SetBackgroundColor(0.3, 0.3, 0.3, 1)
  end
end

local function ItemMouseOut(self)
  local widget = self:GetParent()
  if not widget.enabled then return end
  if not self.selected then
    self:SetBackgroundColor(0, 0, 0, 0)
  end
end


-- Public Functions

local function SetBorder(self, width, r, g, b, a)
  Library.LibSimpleWidgets.SetBorder(self, width, r, g, b, a)
end

local function SetBackgroundColor(self, r, g, b, a)
  self:SetBackgroundColor(r, g, b, a)
end

local function GetFontSize(self)
  return self.fontSize
end

local function SetFontSize(self, size)
  self.fontSize = size
  local height = 0
  for i, itemFrame in ipairs(self.itemFrames) do
    itemFrame:SetFontSize(size)
    itemFrame:SetHeight(itemFrame:GetFullHeight())
    height = height + itemFrame:GetHeight()
  end
  self:SetHeight(height)
end

local function GetEnabled(self)
  return self.enabled
end

local function SetEnabled(self, enabled)
  self.enabled = enabled
  if enabled then
    for i, itemFrame in ipairs(self.itemFrames) do
      itemFrame:SetFontColor(1, 1, 1, 1)
    end
  else
    for i, itemFrame in ipairs(self.itemFrames) do
      itemFrame:SetFontColor(0.5, 0.5, 0.5, 1)
    end
  end
end

local function GetItems(self)
  return self.items
end

local function SetItems(self, items, values)
  self.items = items
  self.values = values or {}

  -- reset the selected item if it doesn't exist in the new items
  local oldSelectedIndex = self.selectedIndex
  self:SetSelectedIndex(nil)

  local height = 0
  local prevItemFrame
  for i, v in ipairs(items) do
    local itemFrame
    if not self.itemFrames[i] then
      itemFrame = UI.CreateFrame("Text", self:GetName().."Item"..i, self)
      if prevItemFrame then
        itemFrame:SetPoint("TOPLEFT", prevItemFrame, "BOTTOMLEFT")
        itemFrame:SetPoint("TOPRIGHT", prevItemFrame, "BOTTOMRIGHT")
      else
        itemFrame:SetPoint("TOPLEFT", self, "TOPLEFT")
        itemFrame:SetPoint("TOPRIGHT", self, "TOPRIGHT")
      end
      itemFrame.Event.LeftClick = ItemClick
      itemFrame.Event.MouseIn = ItemMouseIn
      itemFrame.Event.MouseOut = ItemMouseOut
      itemFrame.index = i
      self.itemFrames[i] = itemFrame
    else
      itemFrame = self.itemFrames[i]
    end
    itemFrame:SetText(v)
    itemFrame:SetHeight(itemFrame:GetFullHeight())
    itemFrame:SetVisible(true)
    height = height + itemFrame:GetHeight()
    prevItemFrame = itemFrame
  end

  if #items < #self.itemFrames then
    for i = #items+1, #self.itemFrames do
      self.itemFrames[i]:SetVisible(false)
    end
  end

  self:SetHeight(height)

  self:SetSelectedIndex(oldSelectedIndex)
end

local function GetValues(self)
  return self.values
end

local function GetSelectedItem(self)
  return self.items[self.selectedIndex]
end

local function SetSelectedItem(self, item)
  if item then
    for i, v in ipairs(self.items) do
      if v == item then
        self:SetSelectedIndex(i)
        return
      end
    end
  end

  self:SetSelectedIndex(nil)
end

local function GetSelectedValue(self)
  return self.values[self.selectedIndex]
end

local function SetSelectedValue(self, value)
  if value then
    for i, v in ipairs(self.values) do
      if v == value then
        self:SetSelectedIndex(i)
        return
      end
    end
  end
  
  self:SetSelectedIndex(nil)
end

local function GetSelectedIndex(self)
  return self.selectedIndex
end

local function SetSelectedIndex(self, index)
  if index and (index < 1 or index > #self.items) then
    index = nil
  end

  if index == self.selectedIndex then
    return
  end
  
  for i, itemFrame in ipairs(self.itemFrames) do
    if i == index then
      itemFrame.selected = true
      itemFrame:SetBackgroundColor(0, 0, 0.5, 1)
    else
      itemFrame.selected = false
      itemFrame:SetBackgroundColor(0, 0, 0, 0)
    end
  end

  local item = self.items[index]
  local value = self.values[index]

  self.selectedIndex = index

  if self.Event.ItemSelect then
    self.Event.ItemSelect(self, item, value, index)
  end

end


-- Constructor Function

function Library.LibSimpleWidgets.List(name, parent)
  local widget = UI.CreateFrame("Frame", name, parent)
  widget:SetBackgroundColor(0, 0, 0, 1)

  widget.enabled = true
  widget.fontSize = 12
  widget.items = {}
  widget.values = {}
  widget.itemFrames = {}
  widget.selectedIndex = nil

  widget.SetBorder = SetBorder
  widget.SetBackgroundColor = SetBackgroundColor
  widget.GetFontSize = GetFontSize
  widget.SetFontSize = SetFontSize
  widget.GetEnabled = GetEnabled
  widget.SetEnabled = SetEnabled
  widget.GetItems = GetItems
  widget.SetItems = SetItems
  widget.GetValues = GetValues
  widget.GetSelectedIndex = GetSelectedIndex
  widget.SetSelectedIndex = SetSelectedIndex
  widget.GetSelectedItem = GetSelectedItem
  widget.SetSelectedItem = SetSelectedItem
  widget.GetSelectedValue = GetSelectedValue
  widget.SetSelectedValue = SetSelectedValue

  Library.LibSimpleWidgets.EventProxy(widget, {"ItemSelect"})

  return widget
end
