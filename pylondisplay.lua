-- This is the CC modem channel
-- used to receive status messages
local statusChannelID = 12

-- Set this to false to prevent displaying the
-- interface on a monitor even if one is attached.
local useMonitor = true

-- Global tables used for states
local status = {}

-- Find Wireless Modem
local modem = peripheral.find("modem", function(n, o) return o.isWireless() end)
if modem == nil then
   error("Could not bind to wireless modem. Is one present?")
end
modem.open(statusChannelID)

-- Find Monitor if one is attached
local monitor = peripheral.find("monitor", function(name, object) return object.isColour() end)
local monWidth, monHeight
local display
local clickEvent
if monitor == nil or useMonitor == false then
   display = term.current()
   clickEvent = "mouse_click"
else
   display = monitor
   display.setTextScale(1.0)
   clickEvent = "monitor_touch"
end
monWidth, monHeight = display.getSize()
if monWidth < 30 and monitor ~= nil then
   display.setTextScale(1.0)
   monWidth, monHeight = display.getSize()
end
display.setBackgroundColor(colors.black)
display.setTextColor(colors.white)

-- Trim whitespace from the lead/trailing
local function trim(s)
   return s:match'^%s*(.*.%S)' or ''
end

local function writeCentered(text, y)
   local x = math.max(math.floor((monWidth / 2) - (#text / 2) + 1), 0)
   display.setCursorPos(x, y)
   display.write(text)
end

local function formatNumber(number)
   local units, value, formatted
   if number < 1000 then
      units = ""
      value = number
   elseif number >= 1000 and number < 1000000 then
      units = "K"
      value = number / 1000
   elseif number >= 1000000 and number < 1000000000 then
      units = "M"
      value = number / 1000000
   elseif number >= 1000000000 and number < 1000000000000 then
      units = "B"
      value = number / 1000000000
   elseif number >= 1000000000000 and number < 1000000000000000 then
      units = "T"
      value = number / 1000000000000
   elseif number >= 1000000000000000 and number < 1000000000000000000 then
      units = "Q"
      value = number / 1000000000000000
   else
      units = "?"
      value = number / 1000000000000000000
   end
   local holder = tostring(value)
   local dot = string.find(holder, '.')
   if dot ~= nil then
      value = tonumber(string.sub(holder, 1, dot + 3))
   end
   formatted = value .. units
   return formatted
end

string.rpad = function(str, len, char)
   if char == nil then char = ' ' end
   return string.rep(char, len - #str) .. str
end

-- Returns the "pairs" of a table iteratively sorted by key
function spairs(t)
   -- collect the keys
   local keys = {}
   for k in pairs(t) do keys[#keys+1] = k end

   table.sort(keys)

   -- return the iterator function
   local i = 0
   return function()
      i = i + 1
      if keys[i] then
         return keys[i], t[keys[i]]
      end
   end
end

local function drawLine(row, color, percent)
   if percent == nil then percent = 100 end
   local drawLength = monWidth - 2
   display.setCursorPos(2, row)
   local filledLength = math.floor(drawLength * (percent / 100))
   local unfilledLength = drawLength - filledLength
   display.setBackgroundColor(color)
   for i=1,filledLength do
      display.write(' ')
   end
   display.setBackgroundColor(colors.gray)
   for i=1,unfilledLength do
      display.write(' ')
   end
   display.setBackgroundColor(colors.black)
end

local function updateDisplay()
   local row = 3
   local formatted
   local count = 0
   local infoColors = {colors.cyan, colors.orange, colors.lime, colors.yellow, colors.magenta, colors.pink}
   local totalCurrent = 0
   local totalMaximum = 0
   for label, info in spairs(status) do
      count = count + 1
      totalCurrent = totalCurrent + info.current
      totalMaximum = totalMaximum + info.maximum
      display.setCursorPos(2, row)
      formatted = formatNumber(info.current)
      display.setTextColor(infoColors[count])
      display.write(label .. ": ")
      display.setTextColor(colors.white)
      display.write(string.rpad(formatted, 7) .. " RF")
      row = row + 1
      display.setCursorPos(2, row)
      formatted = formatNumber(info.maximum)
      display.setTextColor(infoColors[count])
      display.write(label .. ": ")
      display.setTextColor(colors.white)
      display.write(string.rpad(formatted, 7) .. " RF")
      row = row + 1
      drawLine(row, colors.green, math.floor((info.current/info.maximum)*100))
      row = row + 2
   end
   display.setCursorPos(2, row)
   display.setTextColor(colors.purple)
   formatted = formatNumber(totalCurrent)
   display.write("Storage Cur: ")
   display.setTextColor(colors.white)
   display.write(string.rpad(formatted, 6) .. " RF")
   row = row + 1
   display.setCursorPos(2, row)
   display.setTextColor(colors.purple)
   formatted = formatNumber(totalMaximum)
   display.write("Storage Max: ")
   display.setTextColor(colors.white)
   display.write(string.rpad(formatted, 6) .. " RF")
   row = row + 1
   display.setCursorPos(2, row)
   drawLine(row, colors.green, math.floor((totalCurrent/totalMaximum)*100))
end

if useMonitor == true then
   term.clear()
   term.setCursorPos(1,1)
   print("Draconian RF Storage Status Monitor...")
   print()
   if monitor ~= nil then print("Monitor: Present") else print("Monitor: Absent") end
   if modem ~= nil then print("Wireless Modem: Present") else print("Wireless Modem: Absent") end
   print()
   print("Press 'q' to quit")
end

display.clear()
display.setTextColor(colors.red)
writeCentered("Draconian Energy Storage", 1)
display.setTextColor(colors.white)

while true do
   local event, p1, p2, p3, p4, p5 = os.pullEvent()
   -- If 'q' is pressed, then we quit
   if event == "key" then
      if p1 == keys.q then
         term.setCursorPos(1,11)
         return
      end
   -- If we get a modem message, process it for status messages
   elseif event == "modem_message" and p2 == statusChannelID then
      local msgstatus = textutils.unserialize(p4)
      for key, value in pairs(msgstatus) do
         status[key] = value
      end
      updateDisplay()
   end
end
