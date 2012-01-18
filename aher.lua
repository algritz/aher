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
	-- fetch through each emails
	for k, v in pairs(mailList) do
		-- if email hasn't been parsed previously
		if not setContains(mail_history, k) then
			-- open email to have access to details
			Command.Mail.Open(k)
			-- get details
			details = (Inspect.Mail.Detail(k))
			-- parsing each attributes from the email
			mail_details = {}
			for kn, vd in pairs (details) do
				-- read the content of the email
				if (kn == "from") then
					print(kn .. " : " .. vd)
					table.insert(mail_details, vd)
				end
				if (kn == "subject") then
					-- for now, just outputting the content, but will eventually need to parse it
					print(kn .. " : " .. vd)
					table.insert(mail_details, vd)
				end
				if (kn == "attachments" and tonumber(vd) == nil ) then
					table.foreach(vd,print)
					table.insert(mail_details, vd)
				end
				if (kn == "body") then
					-- for now, just outputting the content, but will eventually need to parse it
					print(kn .. " : " .. vd)

					-- Additional email parsing based on body details
					--## HERE
					--

					table.insert(mail_details, vd)
					-- we add email and content to the parsed list
					addToSet(mail_history, k, mail_details)
				end

			end
		end
	end
	print("parsing complete")
end

local function mailstatus()
	for k, v in pairs(mail_history) do
		print(k)
	end
end



local function settingssave()
	mail_history_db = mail_history
end

local function settingsload()
	print("aher settings loading...")
	if mail_history_db ~= nil then
		mail_history = mail_history_db
	else
		print("loading failed")
		mail_history = {}
	end
end


function addToSet(set, key, value)
	set[key] = value
end

function removeFromSet(set, key)
	set[key] = nil
end

function setContains(set, key)
	return set[key]
end
table.insert(Event.Addon.SavedVariables.Save.Begin, {function () settingssave() end, "aher", "Save variables"})
table.insert(Event.Addon.SavedVariables.Load.Begin, {function () settingsload() end, "aher", "Load variables"})

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

table.insert(Command.Slash.Register("aher"), {slashcommands, "aher", "Slash command"})