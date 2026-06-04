-- src/StarterPlayerScripts/AnimationManager.client.luau
-- Reads AnimType attribute on BaseParts and runs corresponding TweenService loops.
-- Works for both pre-existing visible parts and newly revealed (bought) parts.
local TweenService = game:GetService("TweenService")

local function startAnim(part: BasePart)
    if not part:IsA("BasePart") then return end
    local animType = part:GetAttribute("AnimType")
    if not animType then return end
    if part:GetAttribute("_AnimStarted") then return end
    part:SetAttribute("_AnimStarted", true)

    local speed  = part:GetAttribute("AnimSpeed")  or 2
    local offset = part:GetAttribute("AnimOffset") or 0
    local range  = part:GetAttribute("AnimRange")  or 1.5

    if animType == "bob" then
        local baseY = part.Position.Y
        task.delay(offset, function()
            while part.Parent do
                if part.Transparency < 0.5 then
                    local up = TweenService:Create(part,
                        TweenInfo.new(speed/2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                        {Position = Vector3.new(part.Position.X, baseY + range, part.Position.Z)})
                    up:Play(); up.Completed:Wait()
                    if not part.Parent then break end
                    local dn = TweenService:Create(part,
                        TweenInfo.new(speed/2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                        {Position = Vector3.new(part.Position.X, baseY, part.Position.Z)})
                    dn:Play(); dn.Completed:Wait()
                else
                    task.wait(0.5)
                end
            end
        end)

    elseif animType == "spin" then
        local degsPerFrame = (360 / speed) / 30
        task.spawn(function()
            while part.Parent do
                task.wait(1/30)
                if part.Transparency < 0.5 then
                    part.CFrame = part.CFrame * CFrame.Angles(0, math.rad(degsPerFrame), 0)
                end
            end
        end)

    elseif animType == "pulse" then
        task.delay(offset, function()
            while part.Parent do
                if part.Transparency <= 0.1 then
                    local fadeOut = TweenService:Create(part,
                        TweenInfo.new(speed/2, Enum.EasingStyle.Sine),
                        {Transparency = range})
                    fadeOut:Play(); fadeOut.Completed:Wait()
                    if not part.Parent then break end
                    local fadeIn = TweenService:Create(part,
                        TweenInfo.new(speed/2, Enum.EasingStyle.Sine),
                        {Transparency = 0})
                    fadeIn:Play(); fadeIn.Completed:Wait()
                else
                    task.wait(0.5)
                end
            end
        end)

    elseif animType == "strobe" then
        task.delay(offset, function()
            while part.Parent do
                if part.Transparency < 0.5 then
                    part.Transparency = 0
                    task.wait(0.3)
                    if not part.Parent then break end
                    part.Transparency = 1
                    task.wait(math.max(0.1, speed - 0.3))
                else
                    task.wait(0.5)
                end
            end
        end)

    elseif animType == "float" then
        local baseY = part.Position.Y
        task.delay(offset, function()
            while part.Parent do
                if part.Transparency < 0.5 then
                    local rise = TweenService:Create(part,
                        TweenInfo.new(speed, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                        {Position    = Vector3.new(part.Position.X, baseY + range, part.Position.Z),
                         Transparency = 1})
                    rise:Play(); rise.Completed:Wait()
                    if not part.Parent then break end
                    part.Position    = Vector3.new(part.Position.X, baseY, part.Position.Z)
                    part.Transparency = 0
                    task.wait(0.3)
                else
                    task.wait(0.5)
                end
            end
        end)
    end
end

for _, d in ipairs(workspace:GetDescendants()) do
    task.spawn(startAnim, d)
end

workspace.DescendantAdded:Connect(function(inst)
    task.spawn(startAnim, inst)
end)
