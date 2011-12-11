local function createBorderFrame(frame, name)
  local border = frame[name]
  if border then
    return border
  end

  border = UI.CreateFrame("Frame", frame:GetName()..name, frame:GetParent())
  frame[name] = border

  return border
end

function Library.LibSimpleWidgets.SetBorder(frame, width, r, g, b, a)
  -- defaults
  width = width or 1
  r = r or 0
  g = g or 0
  b = b or 0
  a = a or 0

  local bt, bb, bl, br

  -- Re-use the existing borders or create new ones
  bt = createBorderFrame(frame, "LSWTopBorder")
  bb = createBorderFrame(frame, "LSWBottomBorder")
  bl = createBorderFrame(frame, "LSWLeftBorder")
  br = createBorderFrame(frame, "LSWRightBorder")

  -- Hook SetVisible so we can do the same on the borders
  if not frame.OldSetVisible then
    frame.OldSetVisible = frame.SetVisible
    function frame:SetVisible(visible)
      self.LSWTopBorder:SetVisible(visible)
      self.LSWBottomBorder:SetVisible(visible)
      self.LSWLeftBorder:SetVisible(visible)
      self.LSWRightBorder:SetVisible(visible)
      self:OldSetVisible(visible)
    end
  end

  -- top border overlaps the edge of the frame on the left and right to make the corners
  bt:SetBackgroundColor(r, g, b, a)
  bt:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", -width, 0)
  bt:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", width, 0)
  bt:SetHeight(width)
  bt:SetLayer(frame:GetLayer())

  -- bottom border overlaps the edge of the frame on the left and right to make the corners
  bb:SetBackgroundColor(r, g, b, a)
  bb:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -width, 0)
  bb:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", width, 0)
  bb:SetHeight(width)
  bb:SetLayer(frame:GetLayer())

  -- left border
  bl:SetBackgroundColor(r, g, b, a)
  bl:SetPoint("TOPRIGHT", frame, "TOPLEFT", 0, 0)
  bl:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 0, 0)
  bl:SetWidth(width)
  bl:SetLayer(frame:GetLayer())

  -- right border
  br:SetBackgroundColor(r, g, b, a)
  br:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, 0)
  br:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 0, 0)
  br:SetWidth(width)
  br:SetLayer(frame:GetLayer())

  -- Make the borders match the frames current visibility
  bt:SetVisible(frame:GetVisible())
  bb:SetVisible(frame:GetVisible())
  bl:SetVisible(frame:GetVisible())
  br:SetVisible(frame:GetVisible())
end
