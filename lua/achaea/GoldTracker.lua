goldtracker = goldtracker or {}
goldtracker.settings = {}

-- ======================
--	GoldTracker Settings
--	 feel free to edit
-- ======================

-- if you use an ingame command separator, use it here,
-- it'll make party announces much smoother
goldtracker.settings.commandseparator = ";"

-- getalias is for ingame alias to get gold/put gold away
-- very useful if you have a pack that needs opened/closed or
-- if you use nested containers
goldtracker.settings.getalias = false

-- container defaults to pack if left false,
-- and is only used if you leave the above getalias false
goldtracker.settings.container = false

-- if you use a custom prompt function, say with svo,
-- you can put that here to make commands look more natural
goldtracker.settings.promptfunction = false


-- this just copies over any changes you made above
if goldtracker.getsettings then goldtracker.getsettings () end


goldtracker.enabled = goldtracker.enabled or false
goldtracker.prepare = goldtracker.prepare or false
goldtracker.pickup = goldtracker.pickup or false
goldtracker.names = goldtracker.names or {}
goldtracker.paused = goldtracker.paused or {}
goldtracker.num = goldtracker.num or 0
goldtracker.total = goldtracker.total or 0
goldtracker.org = goldtracker.org or {name = false, percent = 0, gold = 0}

goldtracker.getsettings = function ()
	goldtracker.cs = goldtracker.settings.commandseparator
	goldtracker.getalias = goldtracker.settings.getalias
	goldtracker.container = goldtracker.settings.container
	goldtracker.showprompt = goldtracker.settings.promptfunction
end -- func

goldtracker.getsettings ()


goldtracker.echo = function (x)
	Note ("[GoldTracker]: " .. x)
end -- if


goldtracker.display = function ()
	local x = goldtracker.enabled and "enabled" or "disabled"
	Note ("GoldTracker " .. x)
	Note ("			Total gold: " .. goldtracker.total)
	if goldtracker.org.name then
		local name = goldtracker.org.name
		local gold = math.floor (goldtracker.org.gold)
		local percent = goldtracker.org.percent
		Note ("	" .. string.format ("%14s", name:title ()) ..
					 ": " .. string.format ("%-8s", gold) ..
					 " (" .. percent ..	"%)")
	end -- if
	if goldtracker.num > 0 then Note ("\n") end
	for k, v in pairs (goldtracker.names) do
		local v = math.floor (v)
		Note (string.format ("%14s", k:title ()) .. ": " .. v)
	end -- for
	if #goldtracker.paused > 0 then Note ("\n") end
	for k, v in pairs (goldtracker.paused) do
		local v = math.floor (v)
		Note ("	" .. string.format ("%14s", k:title ()) .. ": " .. v)
	end -- for
	-- Note ("<reset>")
end -- func


goldtracker.toggle = function (enabled)
	local x = goldtracker
	enabled = enabled:lower () == "on"
	x.enabled = enabled
	if enabled and x.num == 0 then x.add (string.lower(gmcp.Char.Status.name)) end
	enabled = enabled and "enabled" or "disabled"
	x.echo ("tracking " .. enabled)
end -- func


goldtracker.plus = function (amt, noecho)
	local x = goldtracker
	local i = amt
	if x.org.name then
		x.org.gold =	x.org.gold + i * (x.org.percent/100)
		i = i * ( 1 - x.org.percent/100)
	end -- if
	i = i/x.num
	for k, v in pairs (x.names) do
		x.names[k] = v + i
	end -- for
	x.total = x.total + amt
	if not noecho then
		x.echo ("" .. amt .. " gold added")
	end -- if
end -- func


goldtracker.minus = function (amt)
	local x = goldtracker
	local i = amt
	if x.org.name then
		x.org.gold =	x.org.gold - i * (x.org.percent/100)
		i = i * ( 1 - x.org.percent/100)
	end -- if
	i = i/x.num
	for k, v in pairs (x.names) do
		x.names[k] = v - i
	end -- for
	x.total = x.total - amt
	x.echo ("" .. amt .. " gold removed")
end -- func

 
goldtracker.add = function (name)
	local name = name:lower()
	local x = goldtracker
	if x.names[name] == nil then
		x.echo ("added " .. name:title () .. " to tracking")
		x.names[name] = 0
		x.num = x.num + 1
	else
		x.echo ("" .. name:title () .. " is already being tracked")
	end -- if
end -- func


goldtracker.remove = function (name)
	local name = name:lower()
	local x = goldtracker
	if x.names[name] ~= nil then
		x.echo ("removed " .. name:title () .. " from tracking")
		x.echo ("" .. name:title () .. " was at " .. math.floor (x.names[name]) .. " gold")
		x.names[name] = nil
		x.num = x.num - 1
	else
		x.echo ("" .. name .. " is not currently being tracked")
	end -- if
end -- func


goldtracker.setorg = function (name, percent)
	name = name:lower ()
	local x = goldtracker
	if percent > 100 then
		x.echo ("org percent should be between 0 and 100.")
	elseif x.org.name == name and x.org.percent == percent then
		x.echo ("no change made to the org or percent")
	else
		if x.org.name == false then
			x.echo ("org set to " .. name .. "")
		elseif x.org.name ~= name then
			x.echo ("org changed from " .. x.org.name:title () .. " to " .. name:title ())
		end -- if
		if x.org.percent == 0 then
			x.echo ("org percent set to ".. percent .. "%")
		elseif x.org.percent ~= percent then
			x.echo ("org percent changed from " .. x.org.percent .. "% to " .. percent .. "%")
		end -- if
		x.org.name = name
		x.org.percent = percent
	end -- if
end -- func


goldtracker.unsetorg = function ()
	local x = goldtracker
	if x.org.name == false then
		x.echo ("no org currently set")
	else
		x.echo ("org unset")
		x.echo ("org " .. x.org.name:title () .. " was collecting " ..
						x.org.percent .. "% and had " .. x.org.gold)
	end -- if
	x.org = {name = false, percent = 0, gold = 0}
end -- func


goldtracker.pause = function (name)
	local name = name:lower()
	local x = goldtracker
	if x.names[name] ~= nil then
		x.echo ("gold tracking for " .. name:title () .. " paused")
		x.paused[name] = x.names[name]
		x.names[name] = nil
		x.num = x.num - 1
	else
		x.echo ("" .. name:title () .. " is not currently being tracked")
	end -- if
end -- func


goldtracker.unpause = function (name)
	local name = name:lower()
	local x = goldtracker
	if x.paused[name] then
		x.echo ("gold tracking for " .. name:title () .. " unpaused")
		x.names[name] = x.paused[name]
		x.paused[name] = nil
		x.num = x.num + 1
	else
		x.echo ("" .. name:title () .. " is not currently paused")
	end -- if
end -- func


goldtracker.reset = function ()
	local x = goldtracker
	x.display ()
	x.enabled = false
	x.names = {}
	x.paused = {}
	x.org = {name = false, percent = 0, gold = 0}
	x.num = 0
	x.total = 0
	x.echo ("reset")
end -- func


goldtracker.announce = function (tar, origin)
	if goldtracker.enabled then
		tar = tar:lower ()
		if origin then origin = origin:lower () end
		if tar == "party" and goldtracker.names[origin] then
			local x = ""
			x = "pt We've made " .. goldtracker.total .. " gold this trip."
			if goldtracker.org.name then
				local o = goldtracker.org
				x = x .. goldtracker.cs .. "pt We've collected " .. o.gold .. " gold for " .. o.name:title ()
			end -- if
			for k, v in pairs (goldtracker.names) do
				local gold = math.floor(v)
				x = x .. goldtracker.cs .. "pt	" .. k .. " has " .. gold .. " gold."
			end -- for
			for k, v in pairs (goldtracker.paused) do
				local gold = math.floor(v)
				x = x .. goldtracker.cs .. "pt	" .. k .. " has " .. gold .. " gold - paused."
			end -- for
			Execute (x)
		elseif goldtracker.names[tar] then
			local gold = math.floor (goldtracker.names[tar:lower ()])
			Send ("tell " .. tar .. " You currently have " .. gold .. " gold")
		elseif goldtracker.paused[tar] then
			local gold = math.floor (goldtracker.paused[tar:lower ()])
			Send ("tell " .. tar .. " You currently have " .. gold .. " gold")
		end -- if
	end -- if
end -- func


goldtracker.distribute = function ()
	for k, v in pairs (goldtracker.names) do
		if k ~= gmcp.Char.Status.name:lower () then
			v = math.floor (v)
			Send ("give " .. v .. " money to " .. k)
		end -- if
	end -- for
	for k, v in pairs (goldtracker.paused) do
		if k ~= gmcp.Char.Status.name:lower () then
			v = math.floor (v)
			Send ("give " .. v .. " money to " .. k)
		end -- if
	end -- for
end -- func


goldtracker.distributed = function (name, amt)
	local name = name:lower ()
	local amt = tonumber (amt)
	if not table.contains(goldtracker.names, name) then return end -- if
	if math.floor (goldtracker.names[name]) == amt then
		goldtracker.names[name] = 0
	elseif math.floor (goldtracker.paused[name]) == amt then
		goldtracker.paused[name] = 0
	end -- if
end -- func


goldtracker.help = function ()
		Note ("\n")
		Note ("GOLDTRACKER HELP (use lowercase for commands)\n")
		Note ("\n")
		Note ("	GOLDTRACKER - show the current gold distribution\n")
		Note ("	GOLDTRACKER <ON|OFF> - turn the tracker on or off\n")
		Note ("		Note: the goldtracker will not have any names tracked on\n")
		Note ("		initialization or after reset. Turning the tracker on will\n")
		Note ("		add your name automatically, if no names are being tracked.\n")
		Note ("	GOLDTRACKER <ADD|REMOVE> <name> - add or remove a person\n")
		Note ("	GOLDTRACKER <SET|UNSET> <name> <percent> - allocate to an org\n")
		Note ("	GOLDTRACKER <PAUSE|UNPAUSE> <name> - pause or unpause gold tracking\n")
		Note ("	GOLDTRACKER DISTRIBUTE - attempt to distribute gold\n")
		Note ("	GOLDTRACKER REPORT - provide a gold report over PT\n")
		Note ("	GOLDTRACKER <PLUS|MINUS> <#> - add or remove gold manually\n")
		Note ("	GOLDTRACKER RESET - display the current gold and reset the tracker\n")
		Note ("\n")
		Note ("Settings can be adjusted in the GoldTracker Settings script.\n")
		Note ("You can set a container or ingame alias to get gold, an\n")
		Note ("ingame command separator, and a prompt function.\n")
		Note ("\n")
		Note ("People tracked can say gold report over PT or via tells.\n")
		Note ("\n")
		Note ("For aliases, you can use gold in the place of goldtracker.\n")
		Note ("\n")
end -- func

function GoldTrackerPrompt()
 if goldtracker.enabled and goldtracker.pickup then
	if goldtracker.getalias then
		Send ("queue prepend eqbal " .. goldtracker.getalias)
	else
		Send ("queue prepend eqbal put gold in " .. (goldtracker.container or "pack"))
		Send ("queue prepend eqbal get gold")
	end -- if
end -- if

goldtracker.prepare = false
goldtracker.pickup = false
end -- function


goldtracker.version = "GoldTracker 1.2.1"