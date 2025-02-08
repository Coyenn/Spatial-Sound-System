-- Services
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

-- Client-side validation
if not RunService:IsClient() then
	error("SoundSystemSpatial must run on client. Use RemoteEvents to trigger client-side sound creation.")
end

-- Math utilities
local mathAbs = math.abs
local acos, cos, pi = math.acos, math.cos, math.pi
local v3, cf = Vector3.new, CFrame.new
local dot = v3().Dot

-- Camera setup
local Camera = workspace.CurrentCamera
local FoV = Camera.FieldOfView

Camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
	FoV = Camera.FieldOfView
end)

-- Sound container setup
local SoundContainer = Instance.new("Part")
SoundContainer.Name = "SoundContainer"
SoundContainer.CFrame = cf()
SoundContainer.Anchored = true
SoundContainer.CanCollide = false
SoundContainer.Transparency = 1
SoundContainer.Parent = Camera

-- System core
local SpatialSoundSystem = {}
local CurrentObjects = {}

--[[
	Attaches an existing Sound object to the spatial audio system
	@param SoundObj: Sound instance parented to BasePart/Attachment in workspace
]]
function SpatialSoundSystem:Attach(SoundObj)
	-- Region: Validation
	do
		assert(
			typeof(SoundObj) == "Instance" and SoundObj.ClassName == "Sound",
			"Invalid Sound object (expected Sound instance)"
		)

		assert(SoundObj.Parent and SoundObj:IsDescendantOf(workspace), "Sound must be in workspace hierarchy")

		assert(
			SoundObj.Parent:IsA("Attachment") or SoundObj.Parent:IsA("BasePart"),
			"Sound parent must be BasePart or Attachment"
		)
	end

	-- Region: Equalizer setup
	local Equalizer = Instance.new("EqualizerSoundEffect")
	Equalizer.LowGain = 0
	Equalizer.MidGain = 0
	Equalizer.HighGain = 0
	Equalizer.Parent = SoundObj

	-- Region: Position tracking
	local isAttachment = SoundObj.Parent:IsA("Attachment")
	local emitterPosition = isAttachment and SoundObj.Parent.WorldPosition or SoundObj.Parent.Position

	local PositionTracker = SoundObj.Parent:GetPropertyChangedSignal("Position"):Connect(function()
		emitterPosition = isAttachment and SoundObj.Parent.WorldPosition or SoundObj.Parent.Position
	end)

	CurrentObjects[SoundObj] = emitterPosition

	-- Region: Lifetime management
	SoundObj.AncestryChanged:Connect(function(_, newParent)
		if not newParent then
			CurrentObjects[SoundObj] = nil
			return
		end

		if
			(SoundObj.Parent:IsA("Attachment") or SoundObj.Parent:IsA("BasePart"))
			and SoundObj:IsDescendantOf(workspace)
		then
			PositionTracker:Disconnect()
			PositionTracker = SoundObj.Parent:GetPropertyChangedSignal("Position"):Connect(function()
				emitterPosition = isAttachment and SoundObj.Parent.WorldPosition or SoundObj.Parent.Position
			end)
		else
			CurrentObjects[SoundObj] = nil
		end
	end)
end

--[[
	Creates a new spatial sound emitter
	@param ID: Sound asset ID (numeric string)
	@param Target: Position/CFrame/BasePart/Attachment to follow
	@param Looped: Whether to loop the sound (default: false)
	@returns Created Attachment containing the sound
]]
function SpatialSoundSystem:Create(ID, Target, Looped)
	-- Region: Input validation
	local targetType = typeof(Target)

	assert(
		type(ID) == "string" and ID:match("^%d+$"),
		string.format("Invalid sound ID: %s (expected numeric string)", ID)
	)

	assert(
		targetType == "Vector3" or targetType == "CFrame" or (targetType == "Instance" and Target:IsA("BasePart")),
		"Invalid target type: " .. tostring(targetType)
	)

	-- Region: Emitter setup
	local Emitter = Instance.new("Attachment")
	local shouldLoop = Looped or false

	-- Position tracking
	if targetType == "Instance" then
		RunService.RenderStepped:Connect(function()
			Emitter.WorldPosition = Target.Position
		end)
	elseif targetType == "Vector3" then
		Emitter.WorldPosition = Target
	elseif targetType == "CFrame" then
		Emitter.WorldPosition = Target.Position
	end

	-- Region: Sound creation
	local Sound = Instance.new("Sound")
	Sound.Looped = shouldLoop
	Sound.SoundId = "rbxassetid://" .. ID:match("%d+")

	local Equalizer = Instance.new("EqualizerSoundEffect")
	Equalizer.LowGain = 0
	Equalizer.MidGain = 0
	Equalizer.HighGain = 0
	Equalizer.Parent = Sound

	-- Region: System registration
	CurrentObjects[Emitter] = true

	if not shouldLoop then
		Sound.Ended:Connect(function()
			CurrentObjects[Emitter] = nil
			Emitter:Destroy()
		end)
	end

	-- Region: Hierarchy setup
	Sound.Parent = Emitter
	Emitter.Parent = SoundContainer
	Sound:Play()

	return Emitter
end

-- Region: Spatial processing
RunService.RenderStepped:Connect(function()
	local _, Listener = SoundService:GetListener()
	local listenerCFrame = Listener and Listener:IsA("BasePart") and Listener.CFrame or Camera.CFrame

	for Emitter in pairs(CurrentObjects) do
		local soundPosition = Emitter.WorldPosition
		local listenerPosition = listenerCFrame.Position

		-- Calculate directional vector (horizontal plane only)
		local facing = listenerCFrame.LookVector * v3(1, 0, 1)
		local direction = (soundPosition - listenerPosition).Unit * v3(1, 0, 1)

		-- Calculate attenuation angle
		local dotProduct = mathAbs(dot(facing, direction))
		local angle = acos(math.clamp(dotProduct, 0, 1)) -- Clamp for floating safety

		-- Apply high frequency attenuation
		local attenuation = -25 * ((angle / pi) ^ 2)
		Emitter.Sound.EqualizerSoundEffect.HighGain = attenuation
	end
end)

return SpatialSoundSystem
