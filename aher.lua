local auction_results =   {}

local function GetRGB(hex)
	local tbl = {}
	tbl.r = tonumber("0x" .. string.sub(hex, 1, 2)) / 255
	tbl.g = tonumber("0x" .. string.sub(hex, 3, 4)) / 255
	tbl.b = tonumber("0x" .. string.sub(hex, 5, 6)) / 255
	return tbl
end



local function mailboxparser()
    -- get the list of email
    mailList = Inspect.Mail.List()
    -- fetch through each emails

    for k, v in pairs(mailList) do
       -- open each email to have access to details
      Command.Mail.Open(k)
      -- get details for each
      details = (Inspect.Mail.Detail(k))
      -- parsing each attributes from the email
      for kn, vd in pairs (details) do
        -- found the content of the email
        if (kn == "subject") then
          -- for now, just outputting the content, but will eventually need to parse it
          print(kn .. " : " .. vd)
        end
        if (kn == "body") then
          -- for now, just outputting the content, but will eventually need to parse it
          print(kn .. " : " .. vd)
          -- verify we haven't already processed this email, if not, we add  it to the parsed list
          if not setContains(auction_results, k) then
            addToSet(auction_results, k)
            -- Additional email parsing based on body details
                --## HERE
            --
          end
       end
    end
  end
end

local function mailstatus()
     for k, v in pairs(auction_results) do
          print(k)
     end
end

local function slashcommands(command)
        mailboxparser()
 if(command.match("mailbox",command))then
        print("parsing complete")
 else if(command.match("status",command)) then
        mailstatus()
        print("status report coplete")
 end
end
 end

local function settingssave()
   if item_prices_db then
   	item_prices = item_prices_db
   end
end

local function settingsload()
   if settings ~= {{}}  then
	item_prices_db = item_prices
   else
	item_prices_db = {}
   end
end


function addToSet(set, key)
    set[key] = true
end

function removeFromSet(set, key)
    set[key] = nil
end

function setContains(set, key)
    return set[key]
end


table.insert(Event.Addon.SavedVariables.Save.Begin, {function () settingssave() end, "aher", "Save variables"})
table.insert(Event.Addon.SavedVariables.Load.Begin, {function () settingsload() end, "aher", "Load variables"})


table.insert(Command.Slash.Register("aher"), {slashcommands, "aher", "Slash command"})