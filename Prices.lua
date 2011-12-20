local item_prices_db

local function GetRGB(hex)
	local tbl = {}
	tbl.r = tonumber("0x" .. string.sub(hex, 1, 2)) / 255
	tbl.g = tonumber("0x" .. string.sub(hex, 3, 4)) / 255
	tbl.b = tonumber("0x" .. string.sub(hex, 5, 6)) / 255
	return tbl
end

local function prices()

  local context = UI.CreateContext("SWT_Context")
  SWT_Window = UI.CreateFrame("SimpleWindow", "SWT_Window", context)
  SWT_Window:SetCloseButtonVisible(true)
  SWT_Window:SetTitle("Price List")
  SWT_Window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100, 100)
  SWT_Window:SetWidth(400)
  SWT_Window:SetHeight(400)
  SWT_Window:SetBackgroundColor(3,3,3,0)
  SWT_Window.listScrollView = UI.CreateFrame("SimpleScrollView", "SWT_TestScrollView", SWT_Window:GetContent())
  SWT_Window.listScrollView:SetPoint("TOPLEFT", SWT_Window:GetContent(), "TOPLEFT")
  SWT_Window.listScrollView:SetWidth(370)
  SWT_Window.listScrollView:SetHeight(330)
  SWT_Window.listScrollView:SetBackgroundColor(3,3,3,0)
  SWT_Window.list = UI.CreateFrame("SimpleList", "SWT_TestList", SWT_Window.listScrollView)
  SWT_Window.list.Event.ItemSelect = function(view, item) print("ItemSelect("..item..")") end
  local items = {}
  if item_prices_db ~= nil then
  if item_prices_db[1] ~= nil then
    local entry_count = table.getn(item_prices_db[1])
    for i=1, entry_count do
      table.insert(items, item_prices_db[1][i][1] .. " : " .. item_prices_db[1][i][2] )
    end
    SWT_Window.list:SetItems(items)

    SWT_Window.listScrollView:SetContent(SWT_Window.list)
    else
           items = {"Your Prices.lua file is empty", "Add some values first", "Then log back in"}
           print("Your Prices.lua file is empty, add some values first, then log back in")
           SWT_Window.list:SetItems(items)
    SWT_Window.listScrollView:SetContent(SWT_Window.list)
    end
    else
           items = {"Your Prices.lua file is empty", "Add some values first", "Then log back in"}
           print("Your Prices.lua file is empty, add some values first, then log back in")
           SWT_Window.list:SetItems(items)
           SWT_Window.listScrollView:SetContent(SWT_Window.list)
    end

end

local function pricesListsave()
   if item_prices_db then
   	item_prices = item_prices_db
   end
end

local function pricesListload()
   if item_prices ~= {{}}  then
	item_prices_db = item_prices
   else
	item_prices_db = {}
   end
end


table.insert(Event.Addon.SavedVariables.Save.Begin, {function () pricesListsave() end, "Prices", "Save variables"})
table.insert(Event.Addon.SavedVariables.Load.Begin, {function () pricesListload() end, "Prices", "Load variables"})


table.insert(Command.Slash.Register("prices"), {function () prices() end, "Prices", "Slash command"})