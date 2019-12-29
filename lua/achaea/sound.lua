local dir = require "pl.dir"
local path = require "pl.path"
local stringx = require "pl.stringx"

soundext = {".ogg", ".wav", ".mp3"}
SOUND_PATH = GetInfo(67).."/sounds"

function playSound(soundname)
	local sound = findGameSound(soundname)
	if sound then
		return Sound(sound)
	end -- if
end -- function

function findGameSound(soundname)
	local sound
	local soundpath = SOUND_PATH.."/"..soundname
	if path.isdir(soundpath) then
		local sounds = dir.getfiles(soundpath)
		sound = sounds[math.random(#sounds)]
	end -- if
	local soundpath = SOUND_PATH.."/"..soundname
	if path.isfile(soundpath) then
		local sound = soundpath
	else
		for _, v in ipairs(soundext) do
			if path.isfile(soundpath..v) then
				sound = soundpath..v
			end -- if
		end -- for
	end -- if
	return sound
end -- function
