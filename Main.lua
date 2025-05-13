-- Pathfinding Module where caller sets the Target
local Module = {}

-- Services
local PathfindingService = game:GetService("PathfindingService")

-- Storage for active entities
local Entities = {}

-- Multiplier to adjust chase smoothness
local UPDATE_MULTIPLIER = 1

-- Lookup table for update intervals based on distance
local UpdateTimes = {
	[9999] = 2,
	[40] = 1,
	[15] = 0.35,
	[8] = 0.1
}

-- Computes the appropriate update time based on distance thresholds
local function CalculateUpdateTime(Distance)
	local Chosen = 4
	for Threshold, Interval in pairs(UpdateTimes) do
		if Distance <= Threshold and Interval < Chosen then
			Chosen = Interval
		end
	end
	return Chosen
end



-- Validates and computes path toward the entity's Target
local function GetTarget(Entity, RootPart)
	local Target = Entity.Target
	if not Target then return nil, nil, nil end

	-- Determine target world position
	local TargetPosition
	if typeof(Target) == "Vector3" then
		TargetPosition = Target
	elseif typeof(Target) == "Instance" and Target:IsA("BasePart") then
		TargetPosition = Target.Position
	elseif typeof(Target) == "CFrame" then
		TargetPosition = Target.Position
	else
		warn("Unsupported target type for entity")
		return nil, nil, nil
	end

	-- Check distance range
	local Distance = (RootPart.Position - TargetPosition).Magnitude
	if Distance > Entity.Range then
		return nil, nil, nil
	end

	-- Compute path asynchronously
	local Success, Waypoints = pcall(function()
		Entity.Path:ComputeAsync(RootPart.Position, TargetPosition)
		return Entity.Path:GetWaypoints()
	end)

	if Success and Waypoints and #Waypoints > 0 then
		local UpdateTime = CalculateUpdateTime(Distance)
		return TargetPosition, Waypoints, UpdateTime
	end
	return nil, nil, nil
end

-- Helper to make a humanoid jump
local function SetJump(Humanoid)
	local State = Humanoid:GetState()
	if State ~= Enum.HumanoidStateType.Jumping and State ~= Enum.HumanoidStateType.Freefall then
		Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end

-- Asynchronously follows a list of PathWaypoints
local function FollowWaypoints(Entity, Waypoints)
	local Character = Entity.Character
	if not Character then return end

	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	local RootPart = Character.PrimaryPart or Character:WaitForChild("HumanoidRootPart")
	local DefaultSpeed = Entity.DefaultWalkSpeed

	Entity.Thread = task.spawn(function()
		Entity.ThreadStatus = "Running"

		
		

		for Index = 3, #Waypoints do
			
			-- Wait until Entity is on ground
			while Humanoid.FloorMaterial == Enum.Material.Air do
				task.wait()
			end
			
			local Waypoint = Waypoints[Index]
			Humanoid:MoveTo(Waypoint.Position)
			if Waypoint.Action == Enum.PathWaypointAction.Jump then
				SetJump(Humanoid)
			end

			local Reached = false
			local Connection
			Connection = Humanoid.MoveToFinished:Connect(function()
				Reached = true
				Connection:Disconnect()
			end)

			local StartTime = tick()
			repeat
				task.wait()
			until Reached or (tick() - StartTime) > 0.5
			if (tick() - StartTime) > 0.5 then
				SetJump(Humanoid)
			end
			
			task.spawn(function()
				local NewTarget = GetTarget(Entity, RootPart)
				if NewTarget and Entity.Info == "Roaming" then
					Entity.ThreadStatus = "Dead"
				end
			end)
		end
		
		Entity.ThreadStatus = "Dead"
	end)
end

-- Generates random roam waypoints when no target is found
local function GetRoamPosition(Entity)
	local Character = Entity.Character
	local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
	if not RootPart then return nil end

	local Path = Entity.Path
	for Attempt = 1, 30 do
		local Offset = Vector3.new(
			math.random(-50, 50),
			math.random(-20, 20),
			math.random(-50, 50)
		)
		local RandomPoint = RootPart.Position + Offset
		if (RandomPoint - RootPart.Position).Magnitude > 10 then
			local Ray = workspace:Raycast(RandomPoint, Vector3.new(0, -100, 0))
			if Ray then
				local Success, Wps = pcall(function()
					Path:ComputeAsync(RootPart.Position, Ray.Position)
					return Path:GetWaypoints()
				end)
				if Success and Wps and #Wps > 0 then
					return Wps
				end
			end
		end
		task.wait(0.1)
	end
	return nil
end

-- Main entity loop: chases or roams based on availability of path
local function RunEntity(Entity)
	local Character = Entity.Character
	local RootPart = Character:WaitForChild("HumanoidRootPart")
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")

	-- Optimize network ownership
	for _, Part in ipairs(Character:GetDescendants()) do
		if Part:IsA("BasePart") then
			Part:SetNetworkOwner(nil)
		end
	end

	while Character.Parent do
		local StartTick = tick()
		local TargetPos, Waypoints, UpdateTime = GetTarget(Entity, RootPart)

		-- Cancel any existing follow thread
		if Entity.Thread then
			task.cancel(Entity.Thread)
		end

		if Waypoints then
			Entity.Info = "Chasing"
			FollowWaypoints(Entity, Waypoints)
		else
			Entity.Info = "Stopped"
			if Entity.CanRoam then
				task.wait(1)
				local RoamWps = GetRoamPosition(Entity)
				if RoamWps then
					Entity.Info = "Roaming"
					FollowWaypoints(Entity, RoamWps)
				end
			end
		end

		-- Wait until path thread ends or until update interval elapses
		local WaitInterval = (UpdateTime or 3) / UPDATE_MULTIPLIER
		repeat
			task.wait()
		until (not Entity.Thread or Entity.ThreadStatus == "Dead")
			or (tick() - StartTick) > WaitInterval
	end

	-- Cleanup entity record
	local Index = table.find(Entities, Entity)
	if Index then
		table.remove(Entities, Index)
	end
end

-- Public API: caller sets Entity.Target externally
function Module.CreateChase(Character:Model, AgentRadius:number, CanJump:boolean, Range:number, Costs:{any}, CanRoam:boolean)
	local Path = PathfindingService:CreatePath({
		AgentRadius = AgentRadius or 3,
		AgentHeight = 4.5,
		AgentCanJump = CanJump or false,
		AgentCanClimb = true,
		Costs = Costs
	})

	local Entity = {
		Character = Character,
		Path = Path,
		Info = "Stopped",
		Range = Range or math.huge,
		CanRoam = CanRoam or false,
		Target = nil,
		Thread = nil,
		ThreadStatus = nil
	}
	table.insert(Entities, Entity)
	task.spawn(function() RunEntity(Entity) end)
	return Entity
end

return Module
