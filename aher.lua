local mail_history

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
				print("processed email #" .. processed_mail_count)
				processed_mail_count = processed_mail_count + 1
			end
			
			-- check if we're done processing
			if mail_number == processed_mail_count then
				print("Processing complete")
			end
		end
	end

end


-- output the content of the mail_history database
local function mailstatus()
	for k, v in pairs(mail_history) do
		print(k)
		for kd, vd in pairs(v) do
			print(kd .. " : " .. tostring(vd))
		end
	end
end


-- Save the mail_history database
local function settingssave()
	mail_history_db = mail_history
end

-- reload the mail_history database
local function settingsload()
	print("aher settings loading...")
	if mail_history_db ~= nil then
		mail_history = mail_history_db
	else
		print("loading failed")
		mail_history = {}
	end
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

-- adding the event handler triggers to save/load the databases
table.insert(Event.Addon.SavedVariables.Save.Begin, {function () settingssave() end, "aher", "Save variables"})
table.insert(Event.Addon.SavedVariables.Load.Begin, {function () settingsload() end, "aher", "Load variables"})

-- adding the slash commands parameters
local function slashcommands(command)
	if(command.match("mailbox",command))then
		mailboxparser()
	else if(command.match("status",command)) then
			mailstatus()
			print("status report complete")
		else if(command.match("save",command)) then
				settingssave()
				print("save complete")
			end
		end
	end
end

-- adding the slash commands handler
table.insert(Command.Slash.Register("aher"), {slashcommands, "aher", "Slash command"})