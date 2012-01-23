local auction_pre_process = {}

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


local function process()
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
			addToSet(auction_pre_process, mailkey, auction_details_pre_process)
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
	for othermailkey, othermailvalue in pairs(other_mail_pre_process) do
		-- parse only the attachments, as those are the only ones interesting
		for attachmentkey, attachmentvalue in pairs(othermailvalue[4]) do
			-- verify if the item is in the item_in_inventory database
			if setContains(items_in_inventory, attachmentkey) then
				-- check how many is already owned (some transformations are necessary to get the value
				current_quantity = setContains(items_in_inventory, attachmentkey)
				quantity = {attachmentvalue, current_quantity[2] + 1}
				-- update the quantity
				addToSet(items_in_inventory, attachmentkey, quantity)
				removeFromSet(other_mail_pre_process, othermailkey)
			else
				-- set the quantity to 1 (assume stacks, not stacksize)
				quantity = {attachmentvalue, 1}
				addToSet(items_in_inventory, attachmentkey, quantity)
				removeFromSet(other_mail_pre_process, othermailkey)
			end
		end
		-- add email id to other_email database, so it doesn't get processed ever again.
		addToSet(other_mail, othermailkey, othermailvalue)
	end

	-- process emails comming from the auction house
	for auctionkey, auctionvalue in pairs(auction_pre_process) do
		print("----")
		print(auctionkey)
		-- parse the attachments
		print(auctionvalue[1])
		print(auctionvalue[2])
		print(auctionvalue[3])
		print(auctionvalue[4])
		if auctionvalue[4] ~= nil then
			for attachmentkey, attachmentvalue in pairs(auctionvalue[4]) do
				-- verify if the item is in the item_in_inventory database
				if setContains(items_in_inventory, attachmentkey) then
					-- check how many is already owned (some transformations are necessary to get the value
					current_quantity = setContains(items_in_inventory, attachmentkey)
					quantity = {attachmentvalue, current_quantity[2] + 1}
					-- update the quantity
					addToSet(items_in_inventory, attachmentkey, quantity)
				else
					-- set the quantity to 1 (assume stacks, not stacksize)
					quantity = {attachmentvalue, 1}
					addToSet(items_in_inventory, attachmentkey, quantity)
				end
			end
		end
		-- add email id to auction_results database, so it doesn't get processed ever again.
		addToSet(auction_results_db, auctionkey, auctionvalue)
	end
	print("Processing complete")
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


-- adding the event handler triggers to save/load the databases
table.insert(Event.Addon.SavedVariables.Save.Begin, {function () settingssave() end, "aher", "Save variables"})
table.insert(Event.Addon.SavedVariables.Load.Begin, {function () settingsload() end, "aher", "Load variables"})


-- adding the slash commands parameters
local function slashcommands(command)
	switch(command) : caseof {
	["mailbox"] = function() mailboxparser() end,
	["status"] = function () mailstatus() end,
	["process"] = function() process() end,
	["save"] = function() settingssave() end,
	default = function() printhelp() end,
	}
end

-- adding the slash commands handler
table.insert(Command.Slash.Register("aher"), {slashcommands, "aher", "Slash command"})