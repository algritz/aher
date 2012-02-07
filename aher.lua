-- Coroutines management table
function SetupCoroutineTable()
	coroutine_table = { };
end

-- adds a coroutine to the queue
function AddCoroutine(Item)
	table.insert(coroutine_table, Item);
end

-- remove a coroutine to the queue
function RemoveCoroutine(Index)
	table.remove(coroutine_table, Index);
end

-- resumes a coroutine while it is active
function ResumeCoroutine(Index)
	Item = coroutine_table[Index];
	if coroutine.status(Item) ~= 'dead' then
		coroutine.resume(Item);
	end
end

-- loops through the coroutines lists and calls the resume handler
function ResumeAllCoroutines()
	-- make sure there is something to process
	if coroutine_table ~= {} then
		for Index,Item in ipairs(coroutine_table) do
			ResumeCoroutine(Index);
		end
	else
		return
	end
end

-- pause timer
function Pause(seconds)
	local start = Inspect.Time.Frame()
	while start + seconds > Inspect.Time.Frame() do
		coroutine.yield()
	end
end

-- function that returns the size of a bag
local function get_bag_size(bag_number)
	bag_size = Inspect.Item.Detail(Utility.Item.Slot.Inventory("bag",bag_number))["slots"]
	return bag_size
end

-- function that verifies how much space is left in the bags
local function find_free_space()
	local free_slot = false
	for x=1, 5 do
		for y=1, bag_size(x) do
			current_slot = Utility.Item.Slot.Inventory(x,y)
			current_item = Inspect.Item.Detail(current_slot)
			print(current_item)
			if current_item == nil then
				free_slot = true
			end
		end
	end
	return free_slot
end

-- function that check for the global queue status
local queueStatus = false
local function QueueStatus()
	queueStatus = Inspect.Queue.Status("global")
	if queueStatus then return end -- global queue is still backlogged, var is true so exit out
	queueStatus = false
end

-- small function that opens an email
local function mailOpen(k)
	if not QueueStatus() then
		Command.Mail.Open(k)
	else
		mailOpen(k)
	end
end

-- function that will take the specified attachment from the specified email
local function take_attachment(auctionkey, attachmentvalue)
	if Inspect.Mail.Detail(auctionkey) ~= nil then
		if not QueueStatus() then
			Command.Mail.Take(auctionkey, attachmentvalue)
		else
			take_attachment(auctionkey, attachmentvalue)
		end
		--print(Inspect.Mail.Detail(auctionkey)["attachments"][1])
		if not Inspect.Mail.Detail(auctionkey)["attachments"] == attachmentvalue then
			removeFromSet(ongoing_auctions, attachmentvalue)
		end
	else
		return
	end

end


-- function that will delete an email
local function delete_email(auctionkey)
	if not QueueStatus() then
		Command.Mail.Delete(auctionkey)
	else
		delete_email(auctionkey)
	end
end


local function batch_delete_email()
	if auction_results ~= {} and auction_results ~= nil then
		for auctionkey, auctionvalue in pairs(auction_results) do
			auction_record = {}
			if Inspect.Mail.Detail(auctionkey) ~= nil then
				delete_email(auctionkey)
				Pause(1)
			end
		end
	else
		print("There were no mails from the Auction House to process")
	end
	print("Mailbox cleanup complete")
	RemoveCoroutine(delete_coro)
end

-- output the content of the mail_history database
local function mailstatus(type_of_output)
	switch(type_of_output) : caseof {
	["auction"] = function ()
		for k, v in pairs(auction_results) do
			-- prints out the email ID
			print ("#######################")
			print ("Auction Results")
			print ("#######################")
			print(k)
			-- index to determine what property will be printed
			-- loops through the email attributes
			for kd, vd in pairs(v) do
				print(kd .. " : " .. tostring(vd))
			end
		end
	end,
	["pre-auction"] = function ()
		for k, v in pairs(auction_pre_process) do
			-- prints out the email ID
			print ("#######################")
			print ("Auction Pre-Process")
			print ("#######################")
			print(k)
			-- index to determine what property will be printed
			-- loops through the email attributes
			for kd, vd in pairs(v) do
				print(kd .. " : " .. tostring(vd))
			end
		end
	end,
	["mail"] =	function()
		for k, v in pairs(mail_history) do
			-- prints out the email ID
			print ("#######################")
			print ("Mail History")
			print ("#######################")
			print(k)
			-- index to determine what property will be printed
			-- loops through the email attributes
			for kd, vd in pairs(v) do
				print(kd .. " : " .. tostring(vd))
			end
		end
	end,
	}
	print("status report complete")
end

local function get_all_attachments()
	-- process emails coming from the auction house
	if auction_results ~= {} and auction_results ~= nil then
		for auctionkey, auctionvalue in pairs(auction_results) do
			if Inspect.Mail.Detail(auctionkey) ~= nil then
				auction_record = {}
				-- parsing the attachments
				if auctionvalue[3] ~= nil then
					-- verify if the item is in the item_in_inventory database
					if find_free_space then
						take_attachment(auctionkey, auctionvalue[3])
						Pause(1)
					end
				else
					print("should delete email (seen as empty)")
					delete_email(auctionkey)
					Pause(1)
				end
			end
		end
	else
		print("There were no mails from the Auction House to process")
	end
	print("Processing complete")
	RemoveCoroutine(attachment_coro)
end



local function process()
	if mail_history ~= {} and  mail_history ~= nil then
		print("mail history isn't empty")
		-- processing each email
		for mailkey, mailvalue in pairs(mail_history) do
			-- database that will hold all the data from the auction house results once parsed
			auction_details_pre_process = {}
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
			end
		end

		-- process emails coming from the auction house
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
				if auctionvalue[4][1] ~= nil then
					print("There is an attachment")
					for attachmentkey, attachmentvalue in pairs(auctionvalue[4]) do
						-- verify if the item is in the item_in_inventory database
						if attachmentvalue ~= nil then
							table.insert(auction_record, attachmentvalue)
							if auction_record[1] == "Sold" then
								if setContains(sold_count, attachmentvalue) then
									quantity = setContains(sold, attachmentvalue)
									quantity = quantity + 1
									addToSet(sold_count, attachmentvalue, quantity)
								else
									addToSet(sold_count, attachmentvalue, 1)
								end
								if setContains(prices, attachmentvalue) then
									amount = setContains(prices, attachmentvalue)
									amount = amount * 1.1
									addToSet(prices, attachmentvalue, amount)
								else
									amount = tonumber(platinum .. gold .. silver) * 1.1
									addToSet(prices, attachmentvalue, amount)
								end
								addToSet(expired_count, attachmentvalue, 0)
							else if auction_record[1] == "Expired" then
									if setContains(expired_count, attachmentvalue) then
										quantity = setContains(expired_count, attachmentvalue)
										quantity = quantity + 1
										addToSet(expired_count, attachmentvalue, quantity)
										if math.fmod(quantity, 5) == 0 then
											if setContains(prices, attachmentvalue) then
												amount = setContains(prices, attachmentvalue)
												amount = amount * 0.97
												addToSet(prices, attachmentvalue, amount)
											end
										end
									else
										addToSet(expired_count, attachmentvalue, 1)
									end
								end
							end
						end
					end
				end
				-- add a timestamp for the transaction
				table.insert(auction_record, os.date("%c"))
				-- add email id to auction_results database, so it doesn't get processed ever again. (Filter auctions won for now)
				if string.find(subject, "Auction Won for ") == nil and auction_record[4] ~= nil then
					addToSet(auction_results, auctionkey, auction_record)
				end
			end
		else
			print("There were no mails from the Auction House to process")
		end
		print("Processing complete")
	else
		print("There was nothing to process \n You must parse the mailbox first (/aher mailbox)")
	end
end


local function show_mailbox_window()
	-- display the window
	if mail_window then
		aherMailUI:SetVisible(true)
		mail_window:SetVisible(true)
		return
	end
	-- creating the frame and setting attributes
	mail_window = UI.CreateFrame("RiftWindow", "AHer", aherMailUI)
	mail_window:SetWidth(350)
	mail_window:SetHeight(150)
	mail_window:SetTitle("AHer")
	mail_window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 1125, 75)

	-- storing window size for future usage
	local l, t, r, b = mail_window:GetTrimDimensions()

	-- creating the close button and setting its attributes
	closebutton = UI.CreateFrame("RiftButton", "AHer", mail_window)
	closebutton:SetSkin("close")
	closebutton:SetPoint("TOPRIGHT", mail_window, "TOPRIGHT", r * -1 + 3, b + 2)
	closebutton.Event.LeftPress = function() mail_window:SetVisible(false) end

	-- creating the Read email button and setting its attributes
	scanbutton = UI.CreateFrame("RiftButton", "AHer", mail_window)
	scanbutton:SetText("Read Mails")
	scanbutton:SetPoint("TOPLEFT", mail_window, "TOPLEFT", 45, 55)
	scanbutton.Event.LeftPress = function() launch_mailboxparser() end

	-- creating the Process email button and setting its attributes
	postbutton = UI.CreateFrame("RiftButton", "AHer", mail_window)
	postbutton:SetText("Process Mails")
	postbutton:SetPoint("TOPLEFT", mail_window, "TOPLEFT", 185, 55)
	postbutton.Event.LeftPress = function() process() end
	-- creating the get attachments button and setting its attributes
	postbutton = UI.CreateFrame("RiftButton", "AHer", mail_window)
	postbutton:SetText("Get Attachments")
	postbutton:SetPoint("TOPLEFT", mail_window, "TOPLEFT", 45, 95)
	postbutton.Event.LeftPress = function() launch_attachment_getter() end

	-- creating the delete email button and setting its attributes
	deletebutton = UI.CreateFrame("RiftButton", "AHer", mail_window)
	deletebutton:SetText("Delete Emails")
	deletebutton:SetPoint("TOPLEFT", mail_window, "TOPLEFT", 185, 95)
	deletebutton.Event.LeftPress = function() launch_delete() end
	--deletebutton.Event.LeftPress = function() batch_delete_email() end

end

local function isAtMail()
	local status = Inspect.Interaction("mail")
	if status then
		show_mailbox_window()
	else
		if mail_window ~= nil then
			aherMailUI:SetVisible(false)
			mail_window:SetVisible(false)
		end
	end
end


local function mailboxparser()
	local status = Inspect.Interaction("mail")
	if status == true then
		-- get the list of email
		mailList = Inspect.Mail.List()
		-- checking how many email will be parsed (cannot  use table.getn, since this table contains key/values => only way is to iterate throught the table)
		mail_number = 0
		for k,v in pairs(mailList) do
			mail_number = mail_number + 1
		end
		-- index that stores the nuber of processed emails
		processed_mail_count = 1
		-- fetch through each emails
		for k, v in pairs(mailList) do
			-- if email hasn't been parsed previously
			if not setContains(mail_history, k) or mail_history == {} then
				-- open email to have access to details
				mailOpen(k)
				Pause(1)
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
					processed_mail_count = processed_mail_count + 1
				end

				-- check if we're done processing
				if mail_number == processed_mail_count then
					print("Email recording complete: " .. processed_mail_count .. " entries saved")
					RemoveCoroutine(parsing_coro)
				end
			end
		end
	end
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

local function post_item(item_id, time, value, value, x, y)
	if not QueueStatus() then
		Command.Auction.Post(item_id, time, value, value)
		if setContains(ongoing_auctions, item_id) then
			local quantity =  setContains(ongoing_auctions, item_id)
			quantity = quantity + 1
			addToSet(ongoing_auctions, item_id, quantity)
		else
			addToSet(ongoing_auctions, item_id, 1)
		end
		addToSet(prices, item_id, value)
	else
		Pause(1)
		post_item(item_id, time, value, value, x, y)
	end
end


local function isThereCompetition(item_id)
	for _, auctionid in ipairs(ah_results) do
		auction_detail = Inspect.Auction.Detail(auctionid)
		for key, value in ipairs(auction_detail) do
			if auction_detail ~= {} then
				print("there is competition")
			end
		end
	end
end


local function batch_post_items()
	for x=1, 5 do
		bag_size = get_bag_size(x)
		for y=1, bag_size do
			current_slot = Utility.Item.Slot.Inventory(x,y)
			if (Inspect.Item.Detail(current_slot) and not Inspect.Item.Detail(current_slot)["bound"]) then
				item_id = Inspect.Item.List(current_slot)
				
				isThereCompetition(item_id)
				-- determining value to post for
				local value = 0
				if setContains(prices, Inspect.Item.Detail(current_slot)) ~= nil then
					value = setContains(prices, Inspect.Item.Detail(current_slot))
				else

					if Inspect.Item.Detail(current_slot)["requiredLevel"] ~= nil then
						local level = Inspect.Item.Detail(current_slot)["requiredLevel"]
						value = Inspect.Item.Detail(current_slot)["sell"]
						value = value * 15 * level
					else
						value = Inspect.Item.Detail(current_slot)["sell"]
						value = value * 30
					end
				end
				local deposit_cost = Utility.Auction.Cost(item_id, 12, value, value)
				value = value + deposit_cost
				-- posting the item
				
				
				post_item(item_id, 12, value, value, x, y)
				Pause(1)
			end
		end
		starting_slot=1
	end
	RemoveCoroutine(post_coro)
end


-- adding the main window
local function makewindow()
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
	postbutton.Event.LeftPress = function() launch_post() end
	--postbutton.Event.LeftPress = function() batch_post_items() end
end

local function isAtAH()
	local status = Inspect.Interaction("auction")
	if status then
		makewindow()
	else
		if window ~= nil then
			aherUI:SetVisible(false)
			window:SetVisible(false)
		end
	end
end


-- Save the database
local function settingssave()
	mail_history_db = mail_history
	auction_results_db = auction_results
	items_in_inventory_db = items_in_inventory
	prices_db = prices
	ongoing_auctions_db = ongoing_auctions
	sold_count_db = sold_count
	expired_count_db = expired_count
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
	if auction_pre_process_db ~= nil then
		auction_pre_process = auction_pre_process_db
	else
		auction_pre_process = {}
	end
	if auction_results_db ~= nil then
		auction_results = auction_results_db
	else
		print("loading auction history failed")
		auction_results = {}
	end

	if prices_db ~= nil then
		prices = prices_db
	else
		print("loading prices list failed")
		prices = {}
	end

	if ongoing_auctions_db ~= nil then
		ongoing_auctions = ongoing_auctions_db
	else
		print("loading ongoing auctions list failed")
		ongoing_auctions = {}
	end
	if sold_count_db ~= nil then
		sold_count = sold_count_db
	else
		print("loading sold count list failed")
		sold_count = {}
	end
	if expired_count_db ~= nil then
		expired_count = expired_count_db
	else
		print("loading expired count list failed")
		expired_count = {}
	end
end

local function printhelp()
	print("Available options are: \n status mail : to get the list of mails to process \n status pre : to get the list of auctions to process \n status auc : to get the list of processed auctions")
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
aherMailUI = UI.CreateContext("AHer")

-- adding the event handler triggers to save/load the databases
table.insert(Event.Addon.SavedVariables.Save.Begin, {function () settingssave() end, "aher", "Save variables"})
table.insert(Event.Addon.SavedVariables.Load.Begin, {function () settingsload() end, "aher", "Load variables"})
table.insert(Event.Auction.Scan, {makewindow, "aher", "Process AH data"})
table.insert(Event.Auction.Scan, {AHResults, "aher", "AHResults" })
table.insert(Event.Queue.Status, {QueueStatus, "aher", "Queue Status"})
table.insert(Event.System.Update.Begin, {function() isAtMail() end, "aher", "isAtMail" })
table.insert(Event.System.Update.Begin, {function() isAtAH() end, "aher", "isAtAH" })

SetupCoroutineTable()

table.insert(Event.System.Update.Begin, {function() ResumeAllCoroutines() end, "aher", "OnUpdate" })

function launch_mailboxparser()
	parsing_coro = coroutine.create(mailboxparser)
	AddCoroutine(parsing_coro)
end

function launch_process()
	process_coro = coroutine.create(process)
	AddCoroutine(process_coro)
end

function launch_attachment_getter()
	attachment_coro = coroutine.create(get_all_attachments)
	AddCoroutine(attachment_coro)
end


function launch_post()
	post_coro = coroutine.create(batch_post_items)
	AddCoroutine(post_coro)
end

function launch_delete()
	post_coro = coroutine.create(batch_delete_email)
	AddCoroutine(delete_coro)
end


-- adding the slash commands parameters
local function slashcommands(command)
	switch(command) : caseof {
	["status auc"] = function () mailstatus("auction") end,
	["status pre"] = function () mailstatus("pre-auction") end,
	["status mail"] = function () mailstatus("mail") end,
	default = function() printhelp() end,
	}
end

-- adding the slash commands handler
table.insert(Command.Slash.Register("aher"), {slashcommands, "aher", "Slash command"})