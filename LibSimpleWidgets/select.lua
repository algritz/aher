-- Helper Functions

local function contains(tbl, val)
  for k, v in pairs(tbl) do
    if v == val then
      return true
    end
  end
  return false
end


-- Current Frame Events

local function CurrentClick(self)
  local widget = self:GetParent()
  if not widget.enabled then return end
  local dropdown = widget.dropdown
  dropdown:SetVisible(not dropdown:GetVisible())
end


-- Dropdown Frame Events

local function DropdownItemClick(self)
  local widget = self:GetParent():GetParent()
  local item = self:GetText()
  widget.current:SetText(item)
  widget.dropdown:SetVisible(false)
  widget:SetSelectedIndex(self.index)
end

local function DropdownItemMouseIn(self)
  self:SetBackgroundColor(0.3, 0.3, 0.3, 1)
end

local function DropdownItemMouseOut(self)
  self:SetBackgroundColor(0, 0, 0, 0)
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

local function GetFontSize(self)
  return self.current:GetFontSize()
end

local function SetFontSize(self, size)
  self.current:SetFontSize(size)
  local height = 0
  for i, itemFrame in ipairs(self.itemFrames) do
    itemFrame:SetFontSize(size)
    itemFrame:SetHeight(itemFrame:GetFullHeight())
    height = height + itemFrame:GetHeight()
  end
  self.dropdown:SetHeight(height)
end

local function GetDefaultHeight(self)
  return self.current:GetFullHeight()
end

local function GetDefaultWidth(self)
  local maxWidth = self.current:GetFullWidth()
  for i, itemFrame in ipairs(self.itemFrames) do
    if itemFrame:GetVisible() then
      maxWidth = math.max(maxWidth, itemFrame:GetFullWidth())
    end
  end
  return maxWidth
end

local function ResizeToDefault(self)
  self:SetWidth(self:GetDefaultWidth())
  self:SetHeight(self:GetDefaultHeight())
end

local function GetEnabled(self)
  return self.enabled
end

local function SetEnabled(self, enabled)
  self.enabled = enabled
  if enabled then
    self.current:SetFontColor(1, 1, 1, 1)
  else
    self.current:SetFontColor(0.5, 0.5, 0.5, 1)
    self.dropdown:SetVisible(false)
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
  if not contains(self.items, self:GetSelectedItem()) then
    self.current:SetText("Select...")
  end

  -- setup item frames
  local dropdownHeight = 0
  local prevItemFrame
  for i, v in ipairs(items) do
    local itemFrame
    if not self.itemFrames[i] then
      itemFrame = UI.CreateFrame("Text", self.dropdown:GetName().."Item"..i, self.dropdown)
      if prevItemFrame then
        itemFrame:SetPoint("TOPLEFT", prevItemFrame, "BOTTOMLEFT")
        itemFrame:SetPoint("TOPRIGHT", prevItemFrame, "BOTTOMRIGHT")
      else
        itemFrame:SetPoint("TOPLEFT", self.dropdown, "TOPLEFT")
        itemFrame:SetPoint("TOPRIGHT", self.dropdown, "TOPRIGHT")
      end
      itemFrame.Event.LeftClick = DropdownItemClick
      itemFrame.Event.MouseIn = DropdownItemMouseIn
      itemFrame.Event.MouseOut = DropdownItemMouseOut
      itemFrame.index = i
      self.itemFrames[i] = itemFrame
    else
      itemFrame = self.itemFrames[i]
    end
    itemFrame:SetText(v)
    itemFrame:SetHeight(itemFrame:GetFullHeight())
    itemFrame:SetVisible(true)
    dropdownHeight = dropdownHeight + itemFrame:GetFullHeight()
    prevItemFrame = itemFrame
  end

  -- set unused item frames invisible
  if #items < #self.itemFrames then
    for i = #items+1, #self.itemFrames do
      self.itemFrames[i]:SetVisible(false)
    end
  end

  self.dropdown:SetHeight(dropdownHeight)

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

  local item = self.items[index]
  local value = self.values[index]

  self.selectedIndex = index

  if index == nil then
    self.current:SetText("Select...")
  else
    self.current:SetText(item)
  end

  if self.Event.ItemSelect then
    self.Event.ItemSelect(self, item, value, index)
  end

end


-- Constructor Function

function Library.LibSimpleWidgets.Select(name, parent)
  local widget = UI.CreateFrame("Frame", name, parent)

  widget.enabled = true
  widget.items = {}
  widget.values = {}
  widget.itemFrames = {}
  widget.selectedIndex = nil

  widget.current = UI.CreateFrame("Text", widget:GetName().."Current", widget)
  widget.current:SetAllPoints(widget)
  widget.current:SetBackgroundColor(0, 0, 0, 1)
  widget.current:SetText("Select...")
  widget.current.Event.LeftClick = CurrentClick

  -- TODO: Down arrow button

  widget.dropdown = UI.CreateFrame("Frame", widget:GetName().."Dropdown", widget)
  widget.dropdown:SetBackgroundColor(0, 0, 0, 1)
  widget.dropdown:SetPoint("TOPLEFT", widget.current, "BOTTOMLEFT", 0, 5)
  widget.dropdown:SetPoint("TOPRIGHT", widget.current, "BOTTOMRIGHT", 0, 5)
  widget.dropdown:SetVisible(false)

  widget.SetBorder = SetBorder
  widget.SetBackgroundColor = SetBackgroundColor
  widget.GetFontSize = GetFontSize
  widget.SetFontSize = SetFontSize
  widget.GetDefaultHeight = GetDefaultHeight
  widget.GetDefaultWidth = GetDefaultWidth
  widget.ResizeToDefault = ResizeToDefault
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
