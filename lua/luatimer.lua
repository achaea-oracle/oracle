--[[
	Name: Lua Timer
	Description: Functions to extend and simplify the timer system in MUSHclient.

	Exposed functions:
	tempTimer(time, cmd, cmdtype)
	Creates a temporary, one shot timer. This function returns the unique name of the timer being created.

	Time: Length of the timer in seconds
	Cmd: The command to be executed.
	Cmdtype: Where to send the command (defaults to sendto.script). Todo: sanity check the value of cmdtype.

	Example:
	myTimer = tempTimer(5, "Send("grin")
]]

function convertSeconds (seconds)			
	local hours = math.floor (seconds / 3600)
	seconds = seconds - (hours * 3600)
	local minutes = math.floor (seconds / 60)
	seconds = seconds - (minutes * 60)
	return hours, minutes, seconds
  end -- function
  
function tempTimer(time, cmd, cmdtype)
	local name = "timer_"..math.random(999999999)
	local hour, min, sec = convertSeconds(time)
	local cmd = cmd or ""
	local flags = timer_flag.Enabled + timer_flag.OneShot + timer_flag.Replace + timer_flag.Temporary
	local cmdtype = cmdtype or "sendto.script"
	local e = AddTimer(name, hour, min, sec, cmd, flags)
	if e == error_code.eOK then
		check(SetTimerOption(name, "send_to", cmdtype))
		return name
	else
		print(ErrorDesc(e))
	end -- if
end -- function