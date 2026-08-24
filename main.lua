--==================================================
-- CHAOS RIVAL BETA
-- Roblox Studio LocalScript
-- StarterPlayer > StarterPlayerScripts
--==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Camera = Workspace.CurrentCamera
end)

--==================================================
-- SETTINGS
--==================================================

local Settings = {

	-- AIM ASSIST
	AimbotEnabled = false,
	AimFollowEnabled = true,
	AimLockEnabled = false,

	AimFOV = 20,
	AimDistance = 320,
	AimSmoothness = 0.18,

	BodyRotationEnabled = false,

	TeamCheck = true,
	RequireLineOfSight = true,

	-- PLAYER
	FlyEnabled = false,
	FlySpeed = 45,

	NoclipEnabled = false,

	WalkSpeedEnabled = false,
	WalkSpeed = 16,
	MinWalkSpeed = 8,
	MaxWalkSpeed = 10000,

	-- VISUAL
	ESPEnabled = true,
	ESPHealth = true,
	ESPThroughWalls = true,

	-- CONNECTIONS
	TriggerBotEnabled = false,
	SkinChangerEnabled = false,
	AntiAntiCheatEnabled = false
}

--==================================================
-- CONNECTION MANAGER
--==================================================

local FeatureConnections = {
	Aimbot = {},
	TriggerBot = {},
	AntiAntiCheat = {}
}

local function DisconnectFeature(name)

	local list = FeatureConnections[name]

	if not list then
		return
	end

	for _, connection in ipairs(list) do
		if connection then
			connection:Disconnect()
		end
	end

	table.clear(list)
end

local function AddFeatureConnection(name, connection)

	if connection then
		table.insert(
			FeatureConnections[name],
			connection
		)
	end

	return connection
end

--==================================================
-- FEATURE SLOTS
--==================================================

local function Feature_Aimbot(enabled)

	DisconnectFeature("Aimbot")

	if not enabled then
		return
	end

	-- [[ AIMBOT CONNECTION SLOT ]]
end

local function Feature_TriggerBot(enabled)

	DisconnectFeature("TriggerBot")

	if not enabled then
		return
	end

	-- [[ TRIGGER BOT CONNECTION SLOT ]]
end

local function Feature_SkinChanger(enabled)

	if not enabled then
		return
	end

	-- [[ SKIN CHANGER CONNECTION SLOT ]]
end

local function Feature_AntiAntiCheat(enabled)

	DisconnectFeature("AntiAntiCheat")

	if not enabled then
		return
	end

	-- [[ ANTI-ANTICHEAT CONNECTION SLOT ]]
end

--==================================================
-- CHARACTER HELPERS
--==================================================

local function GetCharacter()
	return LocalPlayer.Character
end

local function GetHumanoid()

	local character = GetCharacter()

	if not character then
		return nil
	end

	return character:FindFirstChildOfClass(
		"Humanoid"
	)
end

local function GetRoot()

	local character = GetCharacter()

	if not character then
		return nil
	end

	return character:FindFirstChild(
		"HumanoidRootPart"
	)
end

--==================================================
-- AIM SYSTEM
--==================================================

local LockedTarget = nil

local function IsEnemy(player)

	if not player
		or player == LocalPlayer then
		return false
	end

	if Settings.TeamCheck then

		if LocalPlayer.Team
			and player.Team
			and LocalPlayer.Team == player.Team then

			return false
		end
	end

	return true
end

local function GetTargetPart(player)

	local character = player.Character

	if not character then
		return nil
	end

	local humanoid =
		character:FindFirstChildOfClass(
			"Humanoid"
		)

	if not humanoid
		or humanoid.Health <= 0 then

		return nil
	end

	return character:FindFirstChild("Head")
		or character:FindFirstChild(
			"HumanoidRootPart"
		)
end

local function IsTargetVisible(part)

	if not Settings.RequireLineOfSight then
		return true
	end

	if not Camera or not part then
		return false
	end

	local origin =
		Camera.CFrame.Position

	local params =
		RaycastParams.new()

	params.FilterType =
		Enum.RaycastFilterType.Exclude

	params.FilterDescendantsInstances = {
		LocalPlayer.Character
	}

	local result =
		Workspace:Raycast(
			origin,
			part.Position - origin,
			params
		)

	if not result then
		return true
	end

	return result.Instance:IsDescendantOf(
		part.Parent
	)
end

local function FindAimTarget()

	if not Camera then
		return nil
	end

	local viewport =
		Camera.ViewportSize

	local center =
		Vector2.new(
			viewport.X * 0.5,
			viewport.Y * 0.5
		)

	local bestTarget = nil
	local bestDistance =
		Settings.AimFOV

	for _, player in ipairs(
		Players:GetPlayers()
	) do

		if IsEnemy(player) then

			local part =
				GetTargetPart(player)

			if part then

				local worldDistance =
					(
						part.Position -
						Camera.CFrame.Position
					).Magnitude

				if worldDistance <=
					Settings.AimDistance then

					local screenPosition,
						onScreen =
						Camera:WorldToViewportPoint(
							part.Position
						)

					if onScreen
						and screenPosition.Z > 0 then

						local pixelDistance =
							(
								Vector2.new(
									screenPosition.X,
									screenPosition.Y
								)
								-
								center
							).Magnitude

						if pixelDistance <=
							bestDistance then

							if IsTargetVisible(
								part
							) then

								bestDistance =
									pixelDistance

								bestTarget =
									player
							end
						end
					end
				end
			end
		end
	end

	return bestTarget
end

local function IsTargetValid(player)

	if not player
		or not IsEnemy(player) then
		return false
	end

	local part =
		GetTargetPart(player)

	if not part then
		return false
	end

	local distance =
		(
			part.Position -
			Camera.CFrame.Position
		).Magnitude

	if distance >
		Settings.AimDistance then
		return false
	end

	return IsTargetVisible(part)
end

local function UpdateAimAssist(dt)

	if not Settings.AimbotEnabled then
		LockedTarget = nil
		return
	end

	if not Camera then
		return
	end

	if LockedTarget then

		if not IsTargetValid(
			LockedTarget
		) then

			LockedTarget = nil
		end
	end

	if not LockedTarget then
		LockedTarget =
			FindAimTarget()
	end

	if not LockedTarget then
		return
	end

	local targetPart =
		GetTargetPart(
			LockedTarget
		)

	if not targetPart then
		LockedTarget = nil
		return
	end

	local current =
		Camera.CFrame

	local desired =
		CFrame.lookAt(
			current.Position,
			targetPart.Position
		)

	if Settings.AimLockEnabled then

		Camera.CFrame =
			desired

	elseif Settings.AimFollowEnabled then

		local smooth =
			math.clamp(
				Settings.AimSmoothness,
				0.01,
				1
			)

		Camera.CFrame =
			current:Lerp(
				desired,
				smooth
			)
	end

	if Settings.BodyRotationEnabled then

		local root =
			GetRoot()

		if root then

			local targetPosition =
				Vector3.new(
					targetPart.Position.X,
					root.Position.Y,
					targetPart.Position.Z
				)

			local bodyTarget =
				CFrame.lookAt(
					root.Position,
					targetPosition
				)

			root.CFrame =
				root.CFrame:Lerp(
					bodyTarget,
					math.clamp(
						10 * dt,
						0,
						1
					)
				)
		end
	end
end

RunService:BindToRenderStep(
	"ChaosAimAssist",
	Enum.RenderPriority.Camera.Value + 1,
	UpdateAimAssist
)

--==================================================
-- WALK SPEED
--==================================================

local DefaultWalkSpeed = 16

local function ApplyWalkSpeed()

	local humanoid = GetHumanoid()

	if not humanoid then
		return
	end

	if Settings.WalkSpeedEnabled then
		humanoid.WalkSpeed =
			Settings.WalkSpeed
	else
		humanoid.WalkSpeed =
			DefaultWalkSpeed
	end
end

RunService.Heartbeat:Connect(function()

	if not Settings.WalkSpeedEnabled then
		return
	end

	local humanoid = GetHumanoid()

	if not humanoid then
		return
	end

	if math.abs(
		humanoid.WalkSpeed -
		Settings.WalkSpeed
	) > 0.01 then

		humanoid.WalkSpeed =
			Settings.WalkSpeed
	end
end)

--==================================================
-- FLY
--==================================================

local FlyAttachment = nil
local FlyVelocity = nil

local function StopFly()

	if FlyVelocity then
		FlyVelocity:Destroy()
		FlyVelocity = nil
	end

	if FlyAttachment then
		FlyAttachment:Destroy()
		FlyAttachment = nil
	end

	local root = GetRoot()

	if root then
		root.AssemblyLinearVelocity =
			Vector3.zero
	end
end

local function StartFly()

	StopFly()

	local root = GetRoot()

	if not root then
		return
	end

	FlyAttachment =
		Instance.new("Attachment")

	FlyAttachment.Name =
		"ChaosFlyAttachment"

	FlyAttachment.Parent =
		root

	FlyVelocity =
		Instance.new("LinearVelocity")

	FlyVelocity.Name =
		"ChaosFlyVelocity"

	FlyVelocity.Attachment0 =
		FlyAttachment

	FlyVelocity.RelativeTo =
		Enum.ActuatorRelativeTo.World

	FlyVelocity.MaxForce =
		math.huge

	FlyVelocity.VectorVelocity =
		Vector3.zero

	FlyVelocity.Parent =
		root
end

RunService.Heartbeat:Connect(function()

	if not Settings.FlyEnabled then
		return
	end

	if not FlyVelocity then
		StartFly()
	end

	if not FlyVelocity or not Camera then
		return
	end

	local direction =
		Vector3.zero

	if UserInputService:IsKeyDown(
		Enum.KeyCode.W
	) then
		direction +=
			Camera.CFrame.LookVector
	end

	if UserInputService:IsKeyDown(
		Enum.KeyCode.S
	) then
		direction -=
			Camera.CFrame.LookVector
	end

	if UserInputService:IsKeyDown(
		Enum.KeyCode.A
	) then
		direction -=
			Camera.CFrame.RightVector
	end

	if UserInputService:IsKeyDown(
		Enum.KeyCode.D
	) then
		direction +=
			Camera.CFrame.RightVector
	end

	if UserInputService:IsKeyDown(
		Enum.KeyCode.Space
	) then
		direction += Vector3.yAxis
	end

	if UserInputService:IsKeyDown(
		Enum.KeyCode.LeftControl
	) then
		direction -= Vector3.yAxis
	end

	if direction.Magnitude > 0 then
		direction =
			direction.Unit
	end

	FlyVelocity.VectorVelocity =
		direction *
		Settings.FlySpeed
end)

--==================================================
-- NOCLIP
--==================================================

RunService.Stepped:Connect(function()

	if not Settings.NoclipEnabled then
		return
	end

	local character = GetCharacter()

	if not character then
		return
	end

	for _, object in ipairs(
		character:GetDescendants()
	) do

		if object:IsA("BasePart") then
			object.CanCollide = false
		end
	end
end)

--==================================================
-- RESPAWN
--==================================================

LocalPlayer.CharacterAdded:Connect(
	function(character)

		LockedTarget = nil
		StopFly()

		local humanoid =
			character:WaitForChild(
				"Humanoid",
				5
			)

		if humanoid then
			task.wait(0.15)
			ApplyWalkSpeed()
		end

		if Settings.FlyEnabled then
			task.wait(0.15)
			StartFly()
		end
	end
)

--==================================================
-- THEME
--==================================================

local THEME = {

	BG_DARK =
		Color3.fromRGB(
			3,
			6,
			12
		),

	TEXT =
		Color3.fromRGB(
			237,
			241,
			248
		),

	SUB =
		Color3.fromRGB(
			145,
			158,
			175
		),

	ACCENT =
		Color3.fromRGB(
			45,
			145,
			255
		),

	ACCENT_LIGHT =
		Color3.fromRGB(
			130,
			210,
			255
		),

	OFF =
		Color3.fromRGB(
			25,
			31,
			40
		),

	LINE =
		Color3.fromRGB(
			32,
			60,
			92
		)
}

local FONT =
	Enum.Font.Code

--==================================================
-- GUI
--==================================================

local Gui =
	Instance.new("ScreenGui")

Gui.Name =
	"ChaosRivalBeta"

Gui.ResetOnSpawn =
	false

Gui.IgnoreGuiInset =
	true

Gui.ZIndexBehavior =
	Enum.ZIndexBehavior.Sibling

Gui.DisplayOrder =
	9999

Gui.Parent =
	LocalPlayer:WaitForChild(
		"PlayerGui"
	)

--==================================================
-- MAIN PANEL
--==================================================

local Panel =
	Instance.new("Frame")

Panel.Name =
	"MainPanel"

Panel.Size =
	UDim2.fromOffset(
		650,
		610
	)

Panel.Position =
	UDim2.new(
		0.04,
		0,
		0.04,
		0
	)

Panel.BackgroundColor3 =
	THEME.BG_DARK

Panel.BorderSizePixel =
	0

Panel.Active =
	true

Panel.ClipsDescendants =
	false

Panel.Parent =
	Gui

local PanelCorner =
	Instance.new("UICorner")

PanelCorner.CornerRadius =
	UDim.new(
		0,
		8
	)

PanelCorner.Parent =
	Panel

--==================================================
-- MAIN BACKGROUND GRADIENT
--==================================================

local BackgroundGradient =
	Instance.new("UIGradient")

BackgroundGradient.Color =
	ColorSequence.new({

		ColorSequenceKeypoint.new(
			0,
			Color3.fromRGB(
				5,
				10,
				24
			)
		),

		ColorSequenceKeypoint.new(
			0.25,
			Color3.fromRGB(
				7,
				20,
				42
			)
		),

		ColorSequenceKeypoint.new(
			0.5,
			Color3.fromRGB(
				4,
				8,
				18
			)
		),

		ColorSequenceKeypoint.new(
			0.75,
			Color3.fromRGB(
				8,
				22,
				45
			)
		),

		ColorSequenceKeypoint.new(
			1,
			Color3.fromRGB(
				3,
				6,
				14
			)
		)
	})

BackgroundGradient.Rotation =
	35

BackgroundGradient.Parent =
	Panel

task.spawn(function()

	while BackgroundGradient.Parent do

		BackgroundGradient.Offset =
			Vector2.new(
				-0.35,
				0
			)

		local tween =
			TweenService:Create(
				BackgroundGradient,
				TweenInfo.new(
					8,
					Enum.EasingStyle.Sine,
					Enum.EasingDirection.InOut
				),
				{
					Offset =
						Vector2.new(
							0.35,
							0
						)
				}
			)

		tween:Play()
		tween.Completed:Wait()

		local reverse =
			TweenService:Create(
				BackgroundGradient,
				TweenInfo.new(
					8,
					Enum.EasingStyle.Sine,
					Enum.EasingDirection.InOut
				),
				{
					Offset =
						Vector2.new(
							-0.35,
							0
						)
				}
			)

		reverse:Play()
		reverse.Completed:Wait()
	end
end)

--==================================================
-- NIGHT SKY AURA
--==================================================

local AuraFrame =
	Instance.new("Frame")

AuraFrame.Size =
	UDim2.new(
		1,
		14,
		1,
		14
	)

AuraFrame.Position =
	UDim2.fromOffset(
		-7,
		-7
	)

AuraFrame.BackgroundTransparency =
	1

AuraFrame.BorderSizePixel =
	0

AuraFrame.Parent =
	Panel

local AuraStroke =
	Instance.new("UIStroke")

AuraStroke.Thickness =
	4

AuraStroke.Transparency =
	0.05

AuraStroke.Parent =
	AuraFrame

local AuraGradient =
	Instance.new("UIGradient")

AuraGradient.Color =
	ColorSequence.new({

		ColorSequenceKeypoint.new(
			0,
			Color3.fromRGB(
				0,
				40,
				105
			)
		),

		ColorSequenceKeypoint.new(
			0.2,
			Color3.fromRGB(
				35,
				120,
				255
			)
		),

		ColorSequenceKeypoint.new(
			0.4,
			Color3.fromRGB(
				0,
				28,
				72
			)
		),

		ColorSequenceKeypoint.new(
			0.6,
			Color3.fromRGB(
				100,
				190,
				255
			)
		),

		ColorSequenceKeypoint.new(
			0.8,
			Color3.fromRGB(
				15,
				65,
				155
			)
		),

		ColorSequenceKeypoint.new(
			1,
			Color3.fromRGB(
				0,
				35,
				90
			)
		)
	})

AuraGradient.Parent =
	AuraStroke

task.spawn(function()

	while AuraGradient.Parent do

		AuraGradient.Offset =
			Vector2.new(
				-1,
				0
			)

		local tween =
			TweenService:Create(
				AuraGradient,
				TweenInfo.new(
					5,
					Enum.EasingStyle.Linear
				),
				{
					Offset =
						Vector2.new(
							1,
							0
						)
				}
			)

		tween:Play()
		tween.Completed:Wait()
	end
end)

--==================================================
-- TITLE
--==================================================

local TitleBar =
	Instance.new("Frame")

TitleBar.Size =
	UDim2.new(
		1,
		0,
		0,
		80
	)

TitleBar.BackgroundColor3 =
	Color3.fromRGB(
		3,
		7,
		15
	)

TitleBar.BackgroundTransparency =
	0.15

TitleBar.BorderSizePixel =
	0

TitleBar.ZIndex =
	2

TitleBar.Parent =
	Panel

local Title =
	Instance.new("TextLabel")

Title.Size =
	UDim2.new(
		1,
		-30,
		0,
		45
	)

Title.Position =
	UDim2.new(
		0,
		15,
		0,
		4
	)

Title.BackgroundTransparency =
	1

Title.Text =
	"CHAOS RIVAL BETA"

Title.TextColor3 =
	THEME.TEXT

Title.Font =
	FONT

Title.TextSize =
	24

Title.TextXAlignment =
	Enum.TextXAlignment.Center

Title.TextYAlignment =
	Enum.TextYAlignment.Center

Title.ZIndex =
	4

Title.Parent =
	TitleBar

local TitleLine =
	Instance.new("Frame")

TitleLine.Size =
	UDim2.new(
		1,
		-70,
		0,
		1
	)

TitleLine.Position =
	UDim2.new(
		0,
		35,
		0,
		58
	)

TitleLine.BackgroundColor3 =
	THEME.ACCENT

TitleLine.BorderSizePixel =
	0

TitleLine.ZIndex =
	4

TitleLine.Parent =
	TitleBar

--==================================================
-- TAB BAR
--==================================================

local TabBar =
	Instance.new("ScrollingFrame")

TabBar.Size =
	UDim2.new(
		1,
		-24,
		0,
		48
	)

TabBar.Position =
	UDim2.fromOffset(
		12,
		80
	)

TabBar.BackgroundTransparency =
	1

TabBar.BorderSizePixel =
	0

TabBar.ScrollBarThickness =
	0

TabBar.AutomaticCanvasSize =
	Enum.AutomaticSize.X

TabBar.CanvasSize =
	UDim2.new(
		0,
		0,
		0,
		0
	)

TabBar.Parent =
	Panel

local TabLayout =
	Instance.new("UIListLayout")

TabLayout.FillDirection =
	Enum.FillDirection.Horizontal

TabLayout.Padding =
	UDim.new(
		0,
		7
	)

TabLayout.VerticalAlignment =
	Enum.VerticalAlignment.Center

TabLayout.Parent =
	TabBar

--==================================================
-- CONTENT
--==================================================

local Content =
	Instance.new("Frame")

Content.Size =
	UDim2.new(
		1,
		-24,
		1,
		-158
	)

Content.Position =
	UDim2.fromOffset(
		12,
		128
	)

Content.BackgroundTransparency =
	1

Content.Parent =
	Panel

--==================================================
-- TAB SYSTEM
--==================================================

local Tabs = {}
local ActivePage = nil

local function SetActiveTab(tab)

	for _, t in ipairs(Tabs) do

		local active =
			t == tab

		t.Button.BackgroundColor3 =
			active
			and Color3.fromRGB(
				16,
				34,
				57
			)
			or Color3.fromRGB(
				8,
				17,
				30
			)

		t.Button.TextColor3 =
			active
			and THEME.ACCENT_LIGHT
			or THEME.SUB

		t.Stroke.Color =
			active
			and THEME.ACCENT
			or THEME.LINE

		t.Underline.Visible =
			active
	end

	if ActivePage then
		ActivePage.Visible =
			false
	end

	ActivePage =
		tab.Page

	ActivePage.Visible =
		true
end

local function CreateTab(name)

	local bounds =
		TextService:GetTextSize(
			name,
			14,
			FONT,
			Vector2.new(
				500,
				40
			)
		)

	local Button =
		Instance.new("TextButton")

	Button.Size =
		UDim2.fromOffset(
			math.max(
				96,
				bounds.X + 34
			),
			34
		)

	Button.BackgroundColor3 =
		Color3.fromRGB(
			8,
			17,
			30
		)

	Button.BorderSizePixel =
		0

	Button.Text =
		name

	Button.TextColor3 =
		THEME.SUB

	Button.Font =
		FONT

	Button.TextSize =
		14

	Button.AutoButtonColor =
		false

	Button.Parent =
		TabBar

	local Corner =
		Instance.new("UICorner")

	Corner.CornerRadius =
		UDim.new(
			0,
			5
		)

	Corner.Parent =
		Button

	local Stroke =
		Instance.new("UIStroke")

	Stroke.Thickness =
		1

	Stroke.Color =
		THEME.LINE

	Stroke.Parent =
		Button

	local Underline =
		Instance.new("Frame")

	Underline.Size =
		UDim2.new(
			1,
			-14,
			0,
			2
		)

	Underline.Position =
		UDim2.new(
			0,
			7,
			1,
			-4
		)

	Underline.BackgroundColor3 =
		THEME.ACCENT

	Underline.BorderSizePixel =
		0

	Underline.Visible =
		false

	Underline.Parent =
		Button

	local Page =
		Instance.new("ScrollingFrame")

	Page.Size =
		UDim2.fromScale(
			1,
			1
		)

	Page.BackgroundTransparency =
		1

	Page.BorderSizePixel =
		0

	Page.ScrollBarThickness =
		4

	Page.ScrollBarImageColor3 =
		THEME.ACCENT

	Page.AutomaticCanvasSize =
		Enum.AutomaticSize.Y

	Page.CanvasSize =
		UDim2.new(
			0,
			0,
			0,
			0
		)

	Page.Visible =
		false

	Page.Parent =
		Content

	local Padding =
		Instance.new("UIPadding")

	Padding.PaddingTop =
		UDim.new(
			0,
			6
		)

	Padding.PaddingBottom =
		UDim.new(
			0,
			8
		)

	Padding.PaddingLeft =
		UDim.new(
			0,
			4
		)

	Padding.PaddingRight =
		UDim.new(
			0,
			4
		)

	Padding.Parent =
		Page

	local Layout =
		Instance.new("UIListLayout")

	Layout.Padding =
		UDim.new(
			0,
			7
		)

	Layout.Parent =
		Page

	local tab = {
		Button = Button,
		Stroke = Stroke,
		Underline = Underline,
		Page = Page
	}

	table.insert(
		Tabs,
		tab
	)

	Button.MouseButton1Click:Connect(
		function()
			SetActiveTab(tab)
		end
	)

	return tab
end

--==================================================
-- FEATURE CARD
--==================================================

local function CreateFeatureCard(
	parent,
	text,
	default,
	callback
)

	local Card =
		Instance.new("Frame")

	Card.Size =
		UDim2.new(
			1,
			0,
			0,
			48
		)

	Card.BackgroundColor3 =
		Color3.fromRGB(
			9,
			18,
			30
		)

	Card.BorderSizePixel =
		0

	Card.Parent =
		parent

	local Corner =
		Instance.new("UICorner")

	Corner.CornerRadius =
		UDim.new(
			0,
			6
		)

	Corner.Parent =
		Card

	local Stroke =
		Instance.new("UIStroke")

	Stroke.Thickness =
		1

	Stroke.Color =
		THEME.LINE

	Stroke.Parent =
		Card

	local Button =
		Instance.new("TextButton")

	Button.Size =
		UDim2.fromScale(
			1,
			1
		)

	Button.BackgroundTransparency =
		1

	Button.Text =
		""

	Button.AutoButtonColor =
		false

	Button.Parent =
		Card

	local Box =
		Instance.new("Frame")

	Box.Size =
		UDim2.fromOffset(
			18,
			18
		)

	Box.Position =
		UDim2.fromOffset(
			14,
			15
		)

	Box.BackgroundColor3 =
		default
		and THEME.ACCENT
		or THEME.OFF

	Box.BorderSizePixel =
		0

	Box.Parent =
		Button

	local Check =
		Instance.new("TextLabel")

	Check.Size =
		UDim2.fromScale(
			1,
			1
		)

	Check.BackgroundTransparency =
		1

	Check.Text =
		default
		and "✓"
		or ""

	Check.TextColor3 =
		Color3.fromRGB(
			4,
			8,
			14
		)

	Check.Font =
		FONT

	Check.TextSize =
		14

	Check.Parent =
		Box

	local Label =
		Instance.new("TextLabel")

	Label.Size =
		UDim2.new(
			1,
			-55,
			1,
			0
		)

	Label.Position =
		UDim2.fromOffset(
			45,
			0
		)

	Label.BackgroundTransparency =
		1

	Label.Text =
		text

	Label.TextColor3 =
		THEME.TEXT

	Label.Font =
		FONT

	Label.TextSize =
		14

	Label.TextXAlignment =
		Enum.TextXAlignment.Left

	Label.Parent =
		Button

	local state =
		default

	local function UpdateVisual()

		Card.BackgroundColor3 =
			state
			and Color3.fromRGB(
				15,
				30,
				50
			)
			or Color3.fromRGB(
				9,
				18,
				30
			)

		Box.BackgroundColor3 =
			state
			and THEME.ACCENT
			or THEME.OFF

		Stroke.Color =
			state
			and THEME.ACCENT
			or THEME.LINE

		Check.Text =
			state
			and "✓"
			or ""
	end

	Button.MouseButton1Click:Connect(
		function()

			state =
				not state

			UpdateVisual()

			callback(
				state
			)
		end
	)

	UpdateVisual()

	return Card
end

--==================================================
-- INFO CARD
--==================================================

local function CreateInfoCard(
	parent,
	text
)

	local Card =
		Instance.new("Frame")

	Card.Size =
		UDim2.new(
			1,
			0,
			0,
			62
		)

	Card.BackgroundColor3 =
		Color3.fromRGB(
			4,
			9,
			17
		)

	Card.BorderSizePixel =
		0

	Card.Parent =
		parent

	local Corner =
		Instance.new("UICorner")

	Corner.CornerRadius =
		UDim.new(
			0,
			6
		)

	Corner.Parent =
		Card

	local Stroke =
		Instance.new("UIStroke")

	Stroke.Thickness =
		1

	Stroke.Color =
		THEME.LINE

	Stroke.Parent =
		Card

	local Label =
		Instance.new("TextLabel")

	Label.Size =
		UDim2.new(
			1,
			-24,
			1,
			-12
		)

	Label.Position =
		UDim2.fromOffset(
			12,
			6
		)

	Label.BackgroundTransparency =
		1

	Label.Text =
		text

	Label.TextColor3 =
		THEME.SUB

	Label.Font =
		FONT

	Label.TextSize =
		12

	Label.TextWrapped =
		true

	Label.TextXAlignment =
		Enum.TextXAlignment.Left

	Label.Parent =
		Card

	return Card
end

--==================================================
-- SLIDER
--==================================================

local function CreateSlider(
	parent,
	text,
	minValue,
	maxValue,
	defaultValue,
	callback
)

	local Card =
		Instance.new("Frame")

	Card.Size =
		UDim2.new(
			1,
			0,
			0,
			82
		)

	Card.BackgroundColor3 =
		Color3.fromRGB(
			9,
			18,
			30
		)

	Card.BorderSizePixel =
		0

	Card.Parent =
		parent

	local Corner =
		Instance.new("UICorner")

	Corner.CornerRadius =
		UDim.new(
			0,
			6
		)

	Corner.Parent =
		Card

	local Stroke =
		Instance.new("UIStroke")

	Stroke.Thickness =
		1

	Stroke.Color =
		THEME.LINE

	Stroke.Parent =
		Card

	local Label =
		Instance.new("TextLabel")

	Label.Size =
		UDim2.new(
			0.65,
			0,
			0,
			24
		)

	Label.Position =
		UDim2.fromOffset(
			12,
			5
		)

	Label.BackgroundTransparency =
		1

	Label.Text =
		text

	Label.TextColor3 =
		THEME.TEXT

	Label.Font =
		FONT

	Label.TextSize =
		14

	Label.TextXAlignment =
		Enum.TextXAlignment.Left

	Label.Parent =
		Card

	local Value =
		Instance.new("TextLabel")

	Value.Size =
		UDim2.new(
			0.3,
			0,
			0,
			24
		)

	Value.Position =
		UDim2.new(
			0.67,
			0,
			0,
			5
		)

	Value.BackgroundTransparency =
		1

	Value.TextColor3 =
		THEME.ACCENT_LIGHT

	Value.Font =
		FONT

	Value.TextSize =
		14

	Value.TextXAlignment =
		Enum.TextXAlignment.Right

	Value.Parent =
		Card

	--================================================
	-- RAIL : BLUE -> BLACK
	--================================================

	local Rail =
		Instance.new("Frame")

	Rail.Size =
		UDim2.new(
			1,
			-24,
			0,
			10
		)

	Rail.Position =
		UDim2.fromOffset(
			12,
			51
		)

	Rail.BackgroundColor3 =
		Color3.fromRGB(
			5,
			10,
			18
		)

	Rail.BorderSizePixel =
		1

	Rail.BorderColor3 =
		Color3.fromRGB(
			38,
			63,
			90
		)

	Rail.Parent =
		Card

	local RailGradient =
		Instance.new("UIGradient")

	RailGradient.Color =
		ColorSequence.new({

			ColorSequenceKeypoint.new(
				0,
				Color3.fromRGB(
					10,
					100,
					205
				)
			),

			ColorSequenceKeypoint.new(
				0.25,
				Color3.fromRGB(
					20,
					85,
					170
				)
			),

			ColorSequenceKeypoint.new(
				0.55,
				Color3.fromRGB(
					10,
					35,
					70
				)
			),

			ColorSequenceKeypoint.new(
				1,
				Color3.fromRGB(
					0,
					0,
					0
				)
			)
		})

	RailGradient.Parent =
		Rail

	--================================================
	-- FILL : BLUE -> BLACK
	--================================================

	local Fill =
		Instance.new("Frame")

	Fill.Size =
		UDim2.new(
			0,
			0,
			1,
			0
		)

	Fill.BackgroundColor3 =
		Color3.fromRGB(
			20,
			100,
			200
		)

	Fill.BorderSizePixel =
		0

	Fill.Parent =
		Rail

	local FillGradient =
		Instance.new("UIGradient")

	FillGradient.Color =
		ColorSequence.new({

			ColorSequenceKeypoint.new(
				0,
				Color3.fromRGB(
					35,
					150,
					255
				)
			),

			ColorSequenceKeypoint.new(
				0.35,
				Color3.fromRGB(
					15,
					90,
					180
				)
			),

			ColorSequenceKeypoint.new(
				0.7,
				Color3.fromRGB(
					5,
					30,
					60
				)
			),

			ColorSequenceKeypoint.new(
				1,
				Color3.fromRGB(
					0,
					0,
					0
				)
			)
		})

	FillGradient.Parent =
		Fill

	--================================================
	-- HANDLE
	-- Rounded black handle, no star
	--================================================

	local Knob =
		Instance.new("Frame")

	Knob.Name =
		"SliderKnob"

	Knob.Size =
		UDim2.fromOffset(
			13,
			20
		)

	Knob.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)

	Knob.Position =
		UDim2.new(
			0,
			0,
			0.5,
			0
		)

	Knob.BackgroundColor3 =
		Color3.fromRGB(
			3,
			5,
			8
		)

	Knob.BorderSizePixel =
		0

	Knob.ZIndex =
		10

	Knob.Parent =
		Rail

	local KnobCorner =
		Instance.new("UICorner")

	KnobCorner.CornerRadius =
		UDim.new(
			0,
			5
		)

	KnobCorner.Parent =
		Knob

	local KnobGradient =
		Instance.new("UIGradient")

	KnobGradient.Color =
		ColorSequence.new({

			ColorSequenceKeypoint.new(
				0,
				Color3.fromRGB(
					45,
					45,
					45
				)
			),

			ColorSequenceKeypoint.new(
				0.5,
				Color3.fromRGB(
					8,
					10,
					13
				)
			),

			ColorSequenceKeypoint.new(
				1,
				Color3.fromRGB(
					0,
					0,
					0
				)
			)
		})

	KnobGradient.Rotation =
		90

	KnobGradient.Parent =
		Knob

	local KnobStroke =
		Instance.new("UIStroke")

	KnobStroke.Thickness =
		1

	KnobStroke.Color =
		Color3.fromRGB(
			70,
			130,
			180
		)

	KnobStroke.Transparency =
		0.15

	KnobStroke.Parent =
		Knob

	local dragging =
		false

	local function SetValue(current)

		current =
			math.clamp(
				current,
				minValue,
				maxValue
			)

		local ratio =
			(
				current -
				minValue
			)
			/
			(
				maxValue -
				minValue
			)

		Fill.Size =
			UDim2.new(
				ratio,
				0,
				1,
				0
			)

		Knob.Position =
			UDim2.new(
				ratio,
				0,
				0.5,
				0
			)

		Value.Text =
			tostring(
				math.floor(
					current
				)
			)

		callback(
			current
		)
	end

	local function UpdateSlider(x)

		local startX =
			Rail.AbsolutePosition.X

		local width =
			Rail.AbsoluteSize.X

		if width <= 0 then
			return
		end

		local ratio =
			math.clamp(
				(x - startX) /
				width,
				0,
				1
			)

		SetValue(
			minValue +
			(
				maxValue -
				minValue
			)
			*
			ratio
		)
	end

	Rail.InputBegan:Connect(
		function(input)

			if input.UserInputType ==
				Enum.UserInputType.MouseButton1
				or
				input.UserInputType ==
				Enum.UserInputType.Touch then

				dragging =
					true

				UpdateSlider(
					input.Position.X
				)
			end
		end
	)

	UserInputService.InputChanged:Connect(
		function(input)

			if not dragging then
				return
			end

			if input.UserInputType ==
				Enum.UserInputType.MouseMovement
				or
				input.UserInputType ==
				Enum.UserInputType.Touch then

				UpdateSlider(
					input.Position.X
				)
			end
		end
	)

	UserInputService.InputEnded:Connect(
		function(input)

			if input.UserInputType ==
				Enum.UserInputType.MouseButton1
				or
				input.UserInputType ==
				Enum.UserInputType.Touch then

				dragging =
					false
			end
		end
	)

	SetValue(
		defaultValue
	)

	return Card
end

--==================================================
-- TABS
--==================================================

local AimbotTab =
	CreateTab("AIMBOT")

local PlayerTab =
	CreateTab("PLAYER")

local VisualTab =
	CreateTab("VISUAL")

local TriggerTab =
	CreateTab("TRIGGER")

local SkinTab =
	CreateTab("SKIN")

local AntiAntiCheatTab =
	CreateTab("ANTI-ANTICHEAT")

--==================================================
-- AIMBOT UI
--==================================================

CreateFeatureCard(
	AimbotTab.Page,
	"Aimbot",
	Settings.AimbotEnabled,
	function(value)

		Settings.AimbotEnabled =
			value

		if not value then
			LockedTarget =
				nil
		end

		Feature_Aimbot(
			value
		)
	end
)

CreateFeatureCard(
	AimbotTab.Page,
	"Aim Follow",
	Settings.AimFollowEnabled,
	function(value)

		Settings.AimFollowEnabled =
			value

		if value then
			Settings.AimLockEnabled =
				false
		end
	end
)

CreateFeatureCard(
	AimbotTab.Page,
	"Aim Lock",
	Settings.AimLockEnabled,
	function(value)

		Settings.AimLockEnabled =
			value

		if value then
			Settings.AimFollowEnabled =
				false
		end
	end
)

CreateFeatureCard(
	AimbotTab.Page,
	"Body Rotation",
	Settings.BodyRotationEnabled,
	function(value)

		Settings.BodyRotationEnabled =
			value
	end
)

CreateFeatureCard(
	AimbotTab.Page,
	"Team Check",
	Settings.TeamCheck,
	function(value)

		Settings.TeamCheck =
			value

		LockedTarget =
			nil
	end
)

CreateFeatureCard(
	AimbotTab.Page,
	"Wall Check",
	Settings.RequireLineOfSight,
	function(value)

		Settings.RequireLineOfSight =
			value

		LockedTarget =
			nil
	end
)

CreateSlider(
	AimbotTab.Page,
	"Aim FOV",
	5,
	100,
	Settings.AimFOV,
	function(value)

		Settings.AimFOV =
			value

		LockedTarget =
			nil
	end
)

CreateSlider(
	AimbotTab.Page,
	"Aim Distance",
	25,
	500,
	Settings.AimDistance,
	function(value)

		Settings.AimDistance =
			value

		LockedTarget =
			nil
	end
)

CreateSlider(
	AimbotTab.Page,
	"Aim Smoothness",
	1,
	100,
	Settings.AimSmoothness * 100,
	function(value)

		Settings.AimSmoothness =
			value / 100
	end
)

--==================================================
-- PLAYER UI
--==================================================

CreateFeatureCard(
	PlayerTab.Page,
	"Fly",
	Settings.FlyEnabled,
	function(value)

		Settings.FlyEnabled =
			value

		if value then
			StartFly()
		else
			StopFly()
		end
	end
)

CreateSlider(
	PlayerTab.Page,
	"Fly Speed",
	10,
	100,
	Settings.FlySpeed,
	function(value)

		Settings.FlySpeed =
			value
	end
)

CreateFeatureCard(
	PlayerTab.Page,
	"Noclip",
	Settings.NoclipEnabled,
	function(value)

		Settings.NoclipEnabled =
			value
	end
)

CreateFeatureCard(
	PlayerTab.Page,
	"Walk Speed",
	Settings.WalkSpeedEnabled,
	function(value)

		Settings.WalkSpeedEnabled =
			value

		ApplyWalkSpeed()
	end
)

CreateSlider(
	PlayerTab.Page,
	"Speed",
	Settings.MinWalkSpeed,
	Settings.MaxWalkSpeed,
	Settings.WalkSpeed,
	function(value)

		Settings.WalkSpeed =
			value

		if Settings.WalkSpeedEnabled then
			ApplyWalkSpeed()
		end
	end
)

CreateInfoCard(
	PlayerTab.Page,
	"Walk Speed: 8 - 10000\n"
	..
	"Selected value is continuously maintained."
)

--==================================================
-- VISUAL UI
--==================================================

CreateFeatureCard(
	VisualTab.Page,
	"ESP",
	Settings.ESPEnabled,
	function(value)

		Settings.ESPEnabled =
			value
	end
)

CreateFeatureCard(
	VisualTab.Page,
	"Health",
	Settings.ESPHealth,
	function(value)

		Settings.ESPHealth =
			value
	end
)

CreateFeatureCard(
	VisualTab.Page,
	"Through Walls",
	Settings.ESPThroughWalls,
	function(value)

		Settings.ESPThroughWalls =
			value
	end
)

CreateInfoCard(
	VisualTab.Page,
	"Visual configuration area."
)

--==================================================
-- TRIGGER UI
--==================================================

CreateFeatureCard(
	TriggerTab.Page,
	"Trigger Bot",
	Settings.TriggerBotEnabled,
	function(value)

		Settings.TriggerBotEnabled =
			value

		Feature_TriggerBot(
			value
		)
	end
)

CreateInfoCard(
	TriggerTab.Page,
	"Connection slot:\n"
	..
	"Feature_TriggerBot()"
)

--==================================================
-- SKIN UI
--==================================================

CreateFeatureCard(
	SkinTab.Page,
	"Skin Changer",
	Settings.SkinChangerEnabled,
	function(value)

		Settings.SkinChangerEnabled =
			value

		Feature_SkinChanger(
			value
		)
	end
)

CreateInfoCard(
	SkinTab.Page,
	"Connection slot:\n"
	..
	"Feature_SkinChanger()"
)

--==================================================
-- ANTI-ANTICHEAT UI
--==================================================

CreateFeatureCard(
	AntiAntiCheatTab.Page,
	"Enable Anti Anti Cheat",
	Settings.AntiAntiCheatEnabled,
	function(value)

		Settings.AntiAntiCheatEnabled =
			value

		Feature_AntiAntiCheat(
			value
		)
	end
)

CreateInfoCard(
	AntiAntiCheatTab.Page,
	"Connection slot:\n"
	..
	"Feature_AntiAntiCheat()"
)

--==================================================
-- DEFAULT TAB
--==================================================

SetActiveTab(
	AimbotTab
)

--==================================================
-- DRAG
--==================================================

local dragging =
	false

local dragStart =
	nil

local startPosition =
	nil

TitleBar.InputBegan:Connect(
	function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or
			input.UserInputType ==
			Enum.UserInputType.Touch then

			dragging =
				true

			dragStart =
				input.Position

			startPosition =
				Panel.Position
		end
	end
)

UserInputService.InputChanged:Connect(
	function(input)

		if not dragging then
			return
		end

		if input.UserInputType ==
			Enum.UserInputType.MouseMovement
			or
			input.UserInputType ==
			Enum.UserInputType.Touch then

			local delta =
				input.Position -
				dragStart

			Panel.Position =
				UDim2.new(
					startPosition.X.Scale,
					startPosition.X.Offset +
					delta.X,

					startPosition.Y.Scale,
					startPosition.Y.Offset +
					delta.Y
				)
		end
	end
)

UserInputService.InputEnded:Connect(
	function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or
			input.UserInputType ==
			Enum.UserInputType.Touch then

			dragging =
				false
		end
	end
)

--==================================================
-- UI TOGGLE
--==================================================

UserInputService.InputBegan:Connect(
	function(
		input,
		gameProcessed
	)

		if gameProcessed then
			return
		end

		if input.KeyCode ==
			Enum.KeyCode.RightShift then

			Panel.Visible =
				not Panel.Visible
		end
	end
)

--==================================================
-- INITIALIZE
--==================================================

Panel.Visible =
	true

ApplyWalkSpeed()

print(
	"[CHAOS RIVAL BETA] Loaded."
)
