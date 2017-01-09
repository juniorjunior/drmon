-- storageNumber is used to identify messages sent from this computer
-- Should be set to something unique
local storageLabel = "Storage #1"
-- statusChannelID is the modem channel number used to send messages
-- This setting can be left alone
local statusChannelID = 12

-- Find Modem
local modem = peripheral.find("modem", function(n, o) return o.isWireless() end)
if modem == nil then
   error("Could not bind to modem. Is one attached?")
end

-- Find Energy Pylon
local pylon = peripheral.find("draconic_rf_storage")
if pylon == nil then
   error("Could not bind to Energy Pylon. Is one adjacent?")
end

term.clear()
term.setCursorPos(1,1)
print("Draconic Energy Storage Monitor...")
print()
print("Stored Energy: ")
print("Maximum Energy: ")
print()
print("Press 'q' to quit")

local status = {}
local pollTimer = os.startTimer(0)
while true do
   local event, p1, p2, p3, p4, p5 = os.pullEvent()
   -- If 'q' is pressed, then we quit
   if event == "key" then
      if p1 == keys.q then
         term.setCursorPos(1,11)
         return
      end
   elseif event == "timer" and p1 == pollTimer then
      local maxEnergy = pylon.getMaxEnergyStored()
      local curEnergy = pylon.getEnergyStored()
      local info = {}
      info["current"] = curEnergy
      info["maximum"] = maxEnergy
      status[storageLabel] = info
      modem.transmit(statusChannelID, 0, textutils.serialize(status))
      term.setCursorPos(16, 3)
      term.write(curEnergy .. "                                         ")
      term.setCursorPos(16, 4)
      term.write(maxEnergy .. "                                         ")
      pollTimer = os.startTimer(5)
   end
end
