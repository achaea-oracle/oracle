local dir = require "pl.dir"
local path = require "pl.path"
local stringx = require "pl.stringx"

require "ppi"
local ppi = ppi.Load("aedf0cb0be5bf045860d54b7") -- add sanity checks

soundext = {".wav", ".ogg", ".mp3"}
SOUND_PATH = GetInfo(67).."/sounds"

function playSound(soundname, loops, pan, vol, pitch)
	local loops = tonumber(loops) or 0
	local pan = tonumber(pan) or 0
	local sound = findGameSound(soundname)
	oracle.debug.print(5, "playSound %s, %s, %s, %s, %s", sound_file or "nil", loops or "nil", pan or "nil", vol or "nil", pitch or "nil")

	if not sound then
		oracle.debug.print(5, "No sound to play.")
		return nil
	end -- if
	local id = ppi.play(sound, loops, pan, vol)
	if tonumber(pitch) and id then
		ppi.setPitch(pitch, id)
	end -- if
	return id
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
