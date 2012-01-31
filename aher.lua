local auction_pre_process = {}

local function GetRGB(hex)
	local tbl = {}
	tbl.r = tonumber("0x" .. string.sub(hex, 1, 2)) / 255
	tbl.g = tonumber("0x" .. string.sub(hex, 3, 4)) / 255
	tbl.b = tonumber("0x" .. string.sub(hex, 5, 6)) / 255
	return tbl
end

function get_bag_size(bag_number)
	bag_size = Inspect.Item.Detail(Utility.Item.Slot.Inventory("bag",bag_number))["slots"]
	return bag_size
end

local function find_free_space()
	local free_slot = false
	for x=1, 5 do
		for y=1, bag_size(x) do
			current_item = Utility.Item.Slot.Inventory(x,y)
			if current_item == nil then
				free_slot = true
			end
		end
	end
	return free_slot
end

local queueStatus = false
local function QueueStatus()
	queueStatus = Inspect.Queue.Status("global")
	if queueStatus then return end -- global queue is still backlogged, var is true so exit out
	queueStatus = false
end


local function take_attachment(auctionkey, attachmentvalue)
	Command.Mail.Take(auctionkey, attachmentvalue)
end

local function process()

	if mail_history ~= {} and  mail_history ~= nil then
		print("Starting to process emails")
		-- processing each email
		for mailkey, mailvalue in pairs(mail_history) do
			-- database that will hold all the data from the auction house results once parsed
			auction_details_pre_process = {}
			other_mail_pre_process = {}
			-- list that will hold the attachments contained in the email
			attachment_list = {}
			i = 1
			-- for each property of the email
			for auctionkey, auctionvalue in pairs(mailvalue) do
				-- store each property (from, subject, body, attachments)
				switch(i) : caseof {
				[1] = function()
					table.insert(auction_details_pre_process, auctionvalue)
				end,
				[2] = function ()
					table.insert(auction_details_pre_process, auctionvalue)
				end,
				[3] = function()
					table.insert(auction_details_pre_process, auctionvalue)
				end,
				[4] = function()
					-- parse through the attachment list (treat as a table in every case as the number can vary)
					for attachmentkey, attachmentvalue in pairs(auctionvalue) do
						table.insert(attachment_list, attachmentvalue)
					end
					table.insert(auction_details_pre_process, attachment_list) end,
				}
				i = i + 1
			end

			-- if the email comes from the auction house, store it and remove it from the email_history (to limit filesize)
			if auction_details_pre_process[1] == "Auction House" then
				if not setContains(auction_results, mailkey) then
					addToSet(auction_pre_process, mailkey, auction_details_pre_process)
				end
				removeFromSet(mail_history, mailkey)
			else
				-- we verify if the other_email has been parsed prior and if not add it to the list to parse
				if not setContains(other_mail, mailkey) then
					addToSet(other_mail_pre_process, mailkey, auction_details_pre_process)
				end
				-- remove the email from the mail_history (which is just a work table)
				removeFromSet(mail_history, mailkey)
			end

		end

		-- process emails not identified as coming from the auction house
		if other_mail_pre_process ~= {} and other_mail_pre_process ~= nil then
			for othermailkey, othermailvalue in pairs(other_mail_pre_process) do
				-- parse only the attachments, as those are the only ones interesting
				for attachmentkey, attachmentvalue in pairs(othermailvalue[4]) do
					-- verify if the item is in the item_in_inventory database
					if setContains(items_in_inventory, attachmentvalue) then
						-- check how many is already owned (some transformations are necessary to get the value
						current_quantity = setContains(items_in_inventory, attachmentvalue)
						quantity = {current_quantity[1]}
						quantity[1] = quantity[1] + 1
						-- update the quantity
						addToSet(items_in_inventory, attachmentvalue, quantity)
						removeFromSet(other_mail_pre_process, othermailkey)
					else
						-- set the quantity to 1 (assume stacks, not stacksize)
						quantity = {1}
						addToSet(items_in_inventory, attachmentvalue, quantity)
						removeFromSet(other_mail_pre_process, othermailkey)
					end
				end
				-- add email id to other_email database, so it doesn't get processed ever again.
				addToSet(other_mail, othermailkey, othermailvalue)
			end
		else
			print("No mails not from Auction house to process")
		end
		-- process emails comming from the auction house
		if auction_pre_process ~= {} and auction_pre_process ~= nil then
			for auctionkey, auctionvalue in pairs(auction_pre_process) do
				auction_record = {}
				-- setting default values
				platinum = "0"
				gold = "00"
				silver = "00"
				-- parse the attachments
				subject = auctionvalue[2]
				-- check if its Expired
				if string.find(subject, "Auction Expired for ") ~= nil then
					-- add the status
					table.insert(auction_record, "Expired")
					-- insert a "null" value as there is no profit
					table.insert(auction_record, "")
				end
				-- Check if its Sold
				if string.find(subject,"Auction Sold for ") ~= nil then
					-- add the status
					table.insert(auction_record, "Sold")
					-- get the email content, in order to parse the profit made
					body = auctionvalue[3]
					-- define where to start and stop looking for
					start_pos = string.find(body, "Bid: ")
					end_pos =  string.find(body, "- Fee: ")
					-- define the profit string
					profit_string = string.sub(body, start_pos + 5, end_pos - 3 )

					-- parsing each currency in order to get how much of each was got
					plat_pos = string.find(profit_string, "platinum")
					-- check if the currency was found
					if plat_pos ~= nil then
						-- extract the amount
						platinum = string.sub(profit_string, 1, plat_pos -1)
						-- remove extra " " (spaces
						platinum = string.gsub(platinum, " ", "")
					end

					gold_pos = string.find(profit_string, "gold")
					if gold_pos ~= nil then
						gold = string.sub(profit_string, gold_pos -3, gold_pos -1)
						gold = string.gsub(gold, " ", "")
						-- if number is beloe 10, add a "0" so it doesn't "offset" the values
						if tonumber(gold) < 10 then
							gold = 0 .. gold
						end
					end

					silver_pos = string.find(profit_string, "silver")
					if silver_pos ~= nil then
						silver = string.sub(profit_string, silver_pos -3, silver_pos -1)
						silver = string.gsub(silver, " ", "")
						if tonumber(silver) < 10 then
							silver = 0 .. silver
						end
					end
					-- add the final amount of the profit to the details of the transaction
					table.insert(auction_record, platinum .. gold .. silver )
				end
				-- parsing the attachments
				if auctionvalue[4] ~= nil then
					for attachmentkey, attachmentvalue in pairs(auctionvalue[4]) do
						-- verify if the item is in the item_in_inventory database
						if auction_record[1] == "Expired" then
							if setContains(items_in_inventory, attachmentvalue) then
								if find_free_space then
									if not QueueStatus()then
										print("Queue is ready, so taking the attachments !")
										take_attachment(auctionkey, attachmentvalue)
									end
									if Inspect.Mail.Detail(auctionkey)["attachments"] == nil then
										if not QueueStatus() then
											Command.Mail.Delete(auctionKey)
											-- check how many are already owned
											current_quantity = setContains(items_in_inventory, attachmentvalue)
											quantity = {current_quantity[1]}
											quantity[1] = quantity[1] + 1
											-- update the quantity
											addToSet(items_in_inventory, attachmentvalue, quantity)
											removeFromSet(auction_pre_process, auctionkey)
										end
									end
								end
							else

								-- set the quantity to 1 (assume stacks, not stacksize)
								if find_free_space then
									if not QueueStatus() then
										print("Queue is ready, so taking the attachments !")
										take_attachment(auctionkey, attachmentvalue)
									end
									if Inspect.Mail.Detail(auctionkey)["attachments"] == nil then
										if not QueueStatus() then
											quantity = {1}
											addToSet(items_in_inventory, attachmentvalue, quantity)
											removeFromSet(auction_pre_process, auctionkey)
											print("should delete the following email:" .. auctionKey)
											Command.Mail.Delete(auctionKey)
										end
									end
								end

							end
						end
						table.insert(auction_record, attachmentvalue)
					end
				end
				-- add a timestamp for the transaction
				table.insert(auction_record, os.date("%c"))
				-- add email id to auction_results database, so it doesn't get processed ever again. (Filter auctions won for now)
				if string.find(subject, "Auction Won for ") == nil then
					addToSet(auction_results, auctionkey, auction_record)
				end
			end
		else
			print("There were no mails from the Auction House to process")
		end
		print("Processing complete")
		table.foreach(mail_history, print)
	else
		print("There was nothing to process \n You must parse the mailbox first (/aher mailbox)")
	end
end


local function mailboxparser()
	local status = Inspect.Interaction("mail")
	if status == true then
		-- get the list of email
		mailList = Inspect.Mail.List()
		-- checking how many email will be parsed (cannot  use table.getn, since this table contains key/values => only way is to iterate throught the table)
		mail_number = 1
		for k,v in pairs(mailList) do
			mail_number = mail_number + 1
		end
		-- index that stores the nuber of processed emails
		processed_mail_count = 1
		-- fetch through each emails
		for k, v in pairs(mailList) do
			-- if email hasn't been parsed previously
			if not setContains(mail_history, k) then
				-- open email to have access to details
				Command.Mail.Open(k)
				-- get details
				details = (Inspect.Mail.Detail(k))
				-- table that will store the mail content
				mail_details = {}
				-- feeding the table
				table.insert(mail_details, details["from"])
				table.insert(mail_details, details["subject"])
				table.insert(mail_details, details["body"])
				--table.insert(mail_details, os.date)
				-- table that will contain teh attachment list if there is any
				attachment_list = {}
				-- detecty if the is any attachment
				if tonumber(details["attachments"]) == nil and details["attachments"] ~= nil then
					-- add item ids in a table
					for ka, va in pairs(details["attachments"]) do
						table.insert(attachment_list, va)
					end
				end
				table.insert(mail_details, attachment_list)
				-- detect if mail is actually "read" (only way to declare the mail as processed)
				if details["body"] ~= nil then
					addToSet(mail_history, k, mail_details)
					print("reading email #" .. processed_mail_count)
					processed_mail_count = processed_mail_count + 1
				end

				-- check if we're done processing
				if mail_number == processed_mail_count then
					print("Email recording complete")
					process()
				end
			end
		end
	end
end


-- output the content of the mail_history database
local function mailstatus()
	-- loops through the mail_history database
	for k, v in pairs(mail_history) do
		-- prints out the email ID
		print ("#######################")
		print(k)
		-- index to determine what property will be printed
		i = 1
		-- loops through the email attributes
		for kd, vd in pairs(v) do
			-- check if "attachment" section is reached (#4)
			if i == 4 then
				-- print out the list of items attached
				print("The following items were attached:")
				for ki, vi in pairs(vd) do
					-- fetch the items detailed informations
					item_details = Inspect.Item.Detail(vi)
					print(item_details["name"])
				end
			else
				-- print out the email attribute and its value
				print(kd .. " : " .. tostring(vd))
			end
			-- increase the counter
			i = i + 1
		end
	end
	print("status report complete")
end


local function AHResults(r1,r2)
	ah_results = {}
	for k,v in pairs(r2) do
		table.insert(ah_results, k)
	end
end

local function scan_ah()
	-- check for interaction with the AH window
	local status = Inspect.Interaction("auction")
	if status == true then
		-- check if the full scan queue is ready
		local full_scan_is_not_queued = Inspect.Queue.Status("auctionfullscan")
		if full_scan_is_not_queued then
			-- determine the type of search
			scan_params = {type="search"}
			-- execute the scan
			Command.Auction.Scan(scan_params)
			table.foreach(ah_results, print)
		else
			print("Full Auction scan is queued, wait a little before scanning again")
		end
	else
		print("You need to open the auction house window first")
	end
end


function post_items()
	for x=1, 5 do
		bag_size = get_bag_size(x)

		for y=1, bag_size do
			current_item = Utility.Item.Slot.Inventory(x,y)
			if (Inspect.Item.Detail(current_item) and not Inspect.Item.Detail(current_item)["bound"]) then
				item_id = Inspect.Item.List(current_item)
				if not QueueStatus() then
					-- posting the item
					Command.Auction.Post(item_id, 12, 10000, 10000)
				end
			end
		end
		starting_slot=1
	end
end


-- adding the main window
function makewindow()
	-- display the window
	if window then
		aherUI:SetVisible(true)
		window:SetVisible(true)
		return
	end
	-- creating the frame and setting attributes
	window = UI.CreateFrame("RiftWindow", "AHer", aherUI)
	window:SetWidth(350)
	window:SetHeight(95)
	window:SetTitle("AHer")
	window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 1125, 75)

	-- storing window size for future usage
	local l, t, r, b = window:GetTrimDimensions()

	-- creating the close button and setting its attributes
	closebutton = UI.CreateFrame("RiftButton", "AHer", window)
	closebutton:SetSkin("close")
	closebutton:SetPoint("TOPRIGHT", window, "TOPRIGHT", r * -1 + 3, b + 2)
	closebutton.Event.LeftPress = function() window:SetVisible(false) end

	-- creating the scan button and setting its attributes
	scanbutton = UI.CreateFrame("RiftButton", "AHer", window)
	scanbutton:SetText("Scan")
	scanbutton:SetPoint("TOPLEFT", window, "TOPLEFT", 45, 55)
	scanbutton.Event.LeftPress = function() scan_ah() end

	-- creating the post button and setting its attributes
	postbutton = UI.CreateFrame("RiftButton", "AHer", window)
	postbutton:SetText("Batch Post")
	postbutton:SetPoint("TOPLEFT", window, "TOPLEFT", 185, 55)
	postbutton.Event.LeftPress = function() post_items() end

end

-- Save the database
local function settingssave()
	mail_history_db = mail_history
	auction_results_db = auction_results
	other_mail_db = other_mail
	items_in_inventory_db = items_in_inventory
end

-- reload the settings database
local function settingsload()
	print("aher settings loading...")
	if mail_history_db ~= nil then
		mail_history = mail_history_db
	else
		print("loading mail history failed")
		mail_history = {}
	end
	if auction_results_db ~= nil then
		auction_results = auction_results_db
	else
		print("loading auction history failed")
		auction_results = {}
	end
	if other_mail_db ~= nil then
		other_mail = other_mail_db
	else
		print("loading other mail history failed")
		other_mail = {}
	end
	if items_in_inventory_db ~= nil then
		items_in_inventory = items_in_inventory_db
	else
		print("loading items_in inventory database failed")
		items_in_inventory = {}
	end
end

local function printhelp()
	print("Available options are: \n mailbox : to parse the mailbox \n status : to get the current status \n save : to force saving of email database")
end


-- These 3 functions will serve to manage the key / values we want to store in the databases (mail_history, auction_history)
function addToSet(set, key, value)
	set[key] = value
end

function removeFromSet(set, key)
	set[key] = nil
end

function setContains(set, key)
	return set[key]
end


-- implementing a switch function as LUA doesn't offer it "out of the box"
function switch(c)
	local swtbl = {
	casevar = c,
	caseof = function (self, code)
		local f
		if (self.casevar) then
			f = code[self.casevar] or code.default
		else
			f = code.missing or code.default
		end
		if f then
			if type(f)=="function" then
				return f(self.casevar,self)
			else
				error("case "..tostring(self.casevar).." not a function")
			end
		end
	end
	}
	return swtbl
end

aherUI = UI.CreateContext("AHer")

-- adding the event handler triggers to save/load the databases
table.insert(Event.Addon.SavedVariables.Save.Begin, {function () settingssave() end, "aher", "Save variables"})
table.insert(Event.Addon.SavedVariables.Load.Begin, {function () settingsload() end, "aher", "Load variables"})
table.insert(Event.Auction.Scan, {function () makewindow() end, "aher", "Process AH data"})
table.insert(Event.Auction.Scan, {AHResults, "aher", "AHResults" })
table.insert(Event.Queue.Status, {QueueStatus, "aher", "Queue Status"})

-- adding the slash commands parameters
local function slashcommands(command)
	switch(command) : caseof {
	["mailbox"] = function() mailboxparser() end,
	["status"] = function () mailstatus() end,
	["save"] = function() settingssave() end,
	["show"] = function() makewindow() end,
	default = function() printhelp() end,
	}
end

-- adding the slash commands handler
table.insert(Command.Slash.Register("aher"), {slashcommands, "aher", "Slash command"})