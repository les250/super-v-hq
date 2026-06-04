-- src/StarterPlayerScripts/MobileController.client.luau
-- Adjusts UI layout for touch devices. Exits immediately on non-mobile.
local UIS = game:GetService("UserInputService")
if not UIS.TouchEnabled then return end

local Players   = game:GetService("Players")
local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

task.wait(3)  -- wait for all other UIs to load

-- Scale up all side toggle buttons for touch targets
local function scaleBtn(guiName, btnClass, newSize, newPos)
    local ui = playerGui:FindFirstChild(guiName)
    if not ui then return end
    local b = ui:FindFirstChildWhichIsA(btnClass)
    if b then
        if newSize then b.Size = newSize end
        if newPos  then b.Position = newPos end
    end
end

-- Objectives toggle button
scaleBtn("ObjectivesUI",  "TextButton", UDim2.new(0,52,0,120), UDim2.new(1,-52,0.5,-60))
-- War Room spy button
scaleBtn("WarRoomUI",     "TextButton", UDim2.new(0,52,0,100), UDim2.new(1,-52,0.5,66))
-- Escape Pod button
scaleBtn("EscapePodUI",   "TextButton", UDim2.new(0,52,0,88),  UDim2.new(1,-52,0.5,174))
-- Inventory bag button
scaleBtn("InventoryPanelUI","TextButton",UDim2.new(0,52,0,88), UDim2.new(0,66,1,-100))
-- Settings gear button
scaleBtn("SettingsUI",    "TextButton", UDim2.new(0,52,0,52),  UDim2.new(0,16,1,-58))

-- Enable larger touch insets by setting ClipsDescendants on all panels
-- (panels are already hidden by default so this is safe)

print("[MobileController] Touch UI adjustments applied")
