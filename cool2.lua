local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local function sendChatMessage(message)
    local success = pcall(function()
        local channels = TextChatService:WaitForChild("TextChannels", 2)
        if channels then
            local generalChannel = channels:WaitForChild("RBXGeneral", 2)
            if generalChannel then
                generalChannel:SendAsync(message)
                return true
            end
        end
    end)
    
    if success then return end

    pcall(function()
        local chatEvent = ReplicatedStorage:FindFirstChild("SayMessageRequest", true)
        if chatEvent then
            chatEvent:FireServer(message, "All")
        end
    end)
end

-- First message in chat
sendChatMessage("script made by Glue Eater.")

-- Send the command for just one hat
local hatId = "4315514742"
sendChatMessage("-gh " .. hatId)

-- Wait for the hat to load into the game
task.wait(2.5)

local realCharacter = player.Character or player.CharacterAdded:Wait()
local realRoot = realCharacter:WaitForChild("HumanoidRootPart")
local realHumanoid = realCharacter:WaitForChild("Humanoid")

realHumanoid.BreakJointsOnDeath = false

-- Find the single accessory handle and clean it up
local targetHandle = nil
for _, item in ipairs(realCharacter:GetChildren()) do
    if item:IsA("Accessory") then
        local handle = item:FindFirstChild("Handle")
        if handle and handle:IsA("BasePart") then
            for _, child in ipairs(handle:GetChildren()) do
                if child:IsA("Weld") or child:IsA("WeldConstraint") or child:IsA("Attachment") then
                    child:Destroy()
                elseif child:IsA("BlockMesh") or child:IsA("CylinderMesh") then
                    child:Destroy()
                end
            end
            
            handle.CanCollide = false
            targetHandle = handle
            break
        end
    end
end

-- 1. Construct R6 fake dummy
local fakeModel = Instance.new("Model")
fakeModel.Name = player.Name .. "_FakeRig"

local function createPart(name, size, canCollide)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Transparency = 1
    part.CanCollide = canCollide or false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    part.Parent = fakeModel
    return part
end

local fakeRoot = createPart("HumanoidRootPart", Vector3.new(2, 2, 1), true)
fakeRoot.Massless = false

local fakeTorso = createPart("Torso", Vector3.new(2, 2, 1), false)
local fakeHead = createPart("Head", Vector3.new(1, 1, 1), false)
local fakeLA = createPart("Left Arm", Vector3.new(1, 2, 1), false)
local fakeRA = createPart("Right Arm", Vector3.new(1, 2, 1), false)
local fakeLL = createPart("Left Leg", Vector3.new(1, 2, 1), false)
local fakeRL = createPart("Right Leg", Vector3.new(1, 2, 1), false)

fakeRoot.CFrame = realRoot.CFrame

local function createMotor(name, part0, part1, c0, c1)
    local motor = Instance.new("Motor6D")
    motor.Name = name
    motor.Part0 = part0
    motor.Part1 = part1
    motor.C0 = c0
    motor.C1 = c1
    motor.Parent = part0
    return motor
end

createMotor("RootJoint", fakeRoot, fakeTorso, CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0))
createMotor("Neck", fakeTorso, fakeHead, CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), CFrame.new(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0))
createMotor("Left Shoulder", fakeTorso, fakeLA, CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CFrame.new(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))
createMotor("Right Shoulder", fakeTorso, fakeRA, CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0))
createMotor("Left Hip", fakeTorso, fakeLL, CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CFrame.new(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))
createMotor("Right Hip", fakeTorso, fakeRL, CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), CFrame.new(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0))

local fakeHumanoid = Instance.new("Humanoid")
fakeHumanoid.RigType = Enum.HumanoidRigType.R6
fakeHumanoid.RequiresNeck = false
fakeHumanoid.HipHeight = 0

fakeHumanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
fakeHumanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
fakeHumanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
fakeHumanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)

fakeHumanoid.Parent = fakeModel
fakeModel.PrimaryPart = fakeRoot
fakeModel.Parent = Workspace

player.Character = fakeModel
camera.CameraSubject = fakeHumanoid
camera.CameraType = Enum.CameraType.Custom

local partMap = {}
for _, item in ipairs(realCharacter:GetChildren()) do
    if item:IsA("BasePart") then
        for _, joint in ipairs(item:GetJoints()) do
            if joint:IsA("Motor6D") or joint:IsA("Weld") or joint:IsA("WeldConstraint") then
                joint:Destroy()
            end
        end
        item.CanCollide = false
        item.CanTouch = false
        item.CanQuery = false
        item.Massless = true
        item.Anchored = false
        
        local matchingFakePart = fakeModel:FindFirstChild(item.Name)
        if matchingFakePart then
            partMap[item] = matchingFakePart
        end
    end
end

if realHumanoid.Health > 0 then
    realHumanoid.Health = 0
end

local rad, sin = math.rad, math.sin
local sine = 0

local neck = fakeTorso:WaitForChild("Neck")
local root = fakeRoot:WaitForChild("RootJoint")
local rs = fakeTorso:WaitForChild("Right Shoulder")
local ls = fakeTorso:WaitForChild("Left Shoulder")
local rh = fakeTorso:WaitForChild("Right Hip")
local lh = fakeTorso:WaitForChild("Left Hip")

local orig_neck = CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)
local orig_root = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)
local orig_rs = CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)
local orig_ls = CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)
local orig_rh = CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)
local orig_lh = CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)

local isEmotingZ = false
local isEmotingE = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.KeyCode == Enum.KeyCode.Z then
            isEmotingZ = not isEmotingZ
            if isEmotingZ then isEmotingE = false end
        elseif input.KeyCode == Enum.KeyCode.E then
            isEmotingE = not isEmotingE
            if isEmotingE then isEmotingZ = false end
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if sethiddenproperty then
            pcall(function()
                sethiddenproperty(player, "MaximumSimulationRadius", 1000)
                sethiddenproperty(player, "SimulationRadius", 1000)
            end)
        end
        if setsimulationradius then
            pcall(function()
                setsimulationradius(1000, 1000)
            end)
        end
    end
end)

RunService.PreSimulation:Connect(function(dt)
    for realPart, _ in pairs(partMap) do
        realPart.CanCollide = false
        realPart.CanTouch = false
        realPart.CanQuery = false
    end

    if realRoot and realRoot.Parent and fakeRoot and fakeRoot.Parent then
        realRoot.CFrame = fakeRoot.CFrame
        realRoot.AssemblyLinearVelocity = Vector3.zero
        realRoot.AssemblyAngularVelocity = Vector3.zero
    end

    sine += dt * 60

    if isEmotingZ then
        neck.Transform = neck.Transform:Lerp(orig_neck.Rotation:Inverse() * CFrame.new(0, 0, 0) * CFrame.Angles(rad(-10), rad(0), rad(0)) * orig_neck.Rotation, 0.15)
        root.Transform = root.Transform:Lerp(orig_root.Rotation:Inverse() * CFrame.new(0, 0.5 * sin((sine) / 20), 0) * CFrame.Angles(rad(45), rad(0), rad(0)) * orig_root.Rotation, 0.15)
        rs.Transform = rs.Transform:Lerp(orig_rs.Rotation:Inverse() * CFrame.new(0, 0, 0.5) * CFrame.Angles(rad(180), rad(0), rad(-45)) * orig_rs.Rotation, 0.15)
        ls.Transform = ls.Transform:Lerp(orig_ls.Rotation:Inverse() * CFrame.new(0, 0, 0.5) * CFrame.Angles(rad(180), rad(0), rad(45)) * orig_ls.Rotation, 0.15)
        rh.Transform = rh.Transform:Lerp(orig_rh.Rotation:Inverse() * CFrame.new(0, 0, 0) * CFrame.Angles(rad(45), rad(0), rad(0)) * orig_rh.Rotation, 0.15)
        lh.Transform = lh.Transform:Lerp(orig_lh.Rotation:Inverse() * CFrame.new(0, 0.3, -0.4) * CFrame.Angles(rad(45), rad(0), rad(30)) * orig_lh.Rotation, 0.15)
    elseif isEmotingE then
        neck.Transform = neck.Transform:Lerp(orig_neck.Rotation:Inverse() * CFrame.new(0, 0, 0) * CFrame.Angles(rad(0), rad(0), rad(10 * sin((sine) / 20))) * orig_neck.Rotation, 0.15)
        root.Transform = root.Transform:Lerp(orig_root.Rotation:Inverse() * CFrame.new(0, -2, 0) * CFrame.Angles(rad(10), rad(0), rad(0)) * orig_root.Rotation, 0.15)
        rs.Transform = rs.Transform:Lerp(orig_rs.Rotation:Inverse() * CFrame.new(0, 0, 0) * CFrame.Angles(rad(-10), rad(0), rad(10 + 10 * sin((sine) / 20))) * orig_rs.Rotation, 0.15)
        ls.Transform = ls.Transform:Lerp(orig_ls.Rotation:Inverse() * CFrame.new(0, 0, 0) * CFrame.Angles(rad(-10), rad(0), rad(-10 + -10 * sin((sine) / 20))) * orig_ls.Rotation, 0.15)
        rh.Transform = rh.Transform:Lerp(orig_rh.Rotation:Inverse() * CFrame.new(0, 0, 0) * CFrame.Angles(rad(80), rad(0), rad(20)) * orig_rh.Rotation, 0.15)
        lh.Transform = lh.Transform:Lerp(orig_lh.Rotation:Inverse() * CFrame.new(0, 0, 0) * CFrame.Angles(rad(80), rad(0), rad(-20)) * orig_lh.Rotation, 0.15)
    elseif fakeHumanoid.MoveDirection.Magnitude > 0.1 then
        neck.Transform = neck.Transform:Lerp(orig_neck.Rotation:Inverse() * CFrame.new(0, 0, 0) * CFrame.Angles(rad(20), rad(0), rad(0)) * orig_neck.Rotation, 0.15)
        root.Transform = root.Transform:Lerp(orig_root.Rotation:Inverse() * CFrame.new(0, 4 + 1 * sin((sine) / 20), 0) * CFrame.Angles(rad(-20), rad(0), rad(0)) * orig_root.Rotation, 0.15)
        rs.Transform = rs.Transform:Lerp(orig_rs.Rotation:Inverse() * CFrame.new(0.9, 0.3, -0.1) * CFrame.Angles(rad(20), rad(180), rad(-45)) * orig_rs.Rotation, 0.15)
        ls.Transform = ls.Transform:Lerp(orig_ls.Rotation:Inverse() * CFrame.new(0, 0, 0) * CFrame.Angles(rad(-45), rad(0), rad(-10)) * orig_ls.Rotation, 0.15)
        rh.Transform = rh.Transform:Lerp(orig_rh.Rotation:Inverse() * CFrame.new(0, 0.5, -0.5) * CFrame.Angles(rad(-20), rad(0), rad(0)) * orig_rh.Rotation, 0.15)
        lh.Transform = lh.Transform:Lerp(orig_lh.Rotation:Inverse() * CFrame.new(0, 0, 0) * CFrame.Angles(rad(-10), rad(0), rad(0)) * orig_lh.Rotation, 0.15)
    else
        neck.Transform = neck.Transform:Lerp(orig_neck.Rotation:Inverse() * CFrame.new(0, 0, 0) * orig_neck.Rotation, 0.15)
        root.Transform = root.Transform:Lerp(orig_root.Rotation:Inverse() * CFrame.new(0, 4 + 1 * sin((sine) / 20), 0) * CFrame.Angles(rad(0), rad(0), rad(0)) * orig_root.Rotation, 0.15)
        rs.Transform = rs.Transform:Lerp(orig_rs.Rotation:Inverse() * CFrame.new(0.9, 0.3, -0.1) * CFrame.Angles(rad(20), rad(180), rad(-45)) * orig_rs.Rotation, 0.15)
        ls.Transform = ls.Transform:Lerp(orig_ls.Rotation:Inverse() * CFrame.new(0, 0, 0) * CFrame.Angles(rad(0), rad(0), rad(-10 + 10 * sin((sine) / 20))) * orig_ls.Rotation, 0.15)
        rh.Transform = rh.Transform:Lerp(orig_rh.Rotation:Inverse() * CFrame.new(0, 0.5, -0.5) * CFrame.Angles(rad(-20), rad(0), rad(0)) * orig_rh.Rotation, 0.15)
        lh.Transform = lh.Transform:Lerp(orig_lh.Rotation:Inverse() * CFrame.new(0, 0, 0) * CFrame.Angles(rad(-10), rad(0), rad(0)) * orig_lh.Rotation, 0.15)
    end
end)

RunService.PostSimulation:Connect(function()
    for realPart, fakePart in pairs(partMap) do
        if realPart.Name ~= "HumanoidRootPart" and fakePart and fakePart.Parent then
            realPart.AssemblyLinearVelocity = Vector3.new(0, 30, 0)
            realPart.CFrame = fakePart.CFrame
        end
    end

    if targetHandle and targetHandle.Parent and fakeRA and fakeRA.Parent then
        targetHandle.AssemblyLinearVelocity = Vector3.new(0, 30, 0)
        targetHandle.CFrame = fakeRA.CFrame * CFrame.new(0.00, -3.50, -4.50) * CFrame.Angles(math.rad(0.00), math.rad(-90.00), math.rad(0.00))
    end
end)
