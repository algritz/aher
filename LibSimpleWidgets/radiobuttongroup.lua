-- Helper Functions

local function UpdateSelected(radioButtons, selected)
  for i, radioButton in ipairs(radioButtons) do
    if radioButton ~= selected then
      radioButton:SetSelected(false)
    end
  end
end

-- Public Functions

local class = {}
class.__index = class

function class:GetName()
  return self.name
end

function class:AddRadioButton(radioButton)
  table.insert(self.radioButtons, radioButton)

  local origRadioButtonSelect = radioButton.Event.RadioButtonSelect
  radioButton.Event.RadioButtonSelect = function(rb)
    if origRadioButtonSelect then
      origRadioButtonSelect(rb)
    end
    UpdateSelected(self.radioButtons, rb)
    if self.Event.RadioButtonChange then
      self.Event.RadioButtonChange(self)
    end
  end
end

function class:RemoveRadioButton(radioButton)
  if type(radioButton) == "number" then
    table.remove(self.radioButtons, radioButton)
  else
    for i, v in ipairs(self.radioButtons) do
      if v == radioButton then
        table.remove(self.radioButtons, i)
      end
    end
  end
end

function class:GetRadioButton(index)
  return self.radioButtons[index]
end

function class:GetSelectedRadioButton()
  for i, radioButton in ipairs(self.radioButtons) do
    if radioButton:GetSelected() then
      return radioButton
    end
  end
end

function class:GetSelectedIndex()
  for i, radioButton in ipairs(self.radioButtons) do
    if radioButton:GetSelected() then
      return i
    end
  end
end

-- Constructor Function

function Library.LibSimpleWidgets.RadioButtonGroup(name)
  local group = {}
  setmetatable(group, class)
  group.name = name
  group.radioButtons = {}
  Library.LibSimpleWidgets.EventProxy(group, { "RadioButtonChange" })
  return group
end
