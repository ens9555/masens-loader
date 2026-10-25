--[[
	MasensDev Premium - Loader (sistem key + kunci device)
	File INI yang boleh publik (GitHub). Script utama TIDAK ada di sini,
	script utama hanya dikirim server setelah key valid.

	Cara pakai pemain:
	loadstring(game:HttpGet("https://raw.githubusercontent.com/USERNAME/REPO/main/Loader.lua"))()
]]

local API_URL  = "https://script.google.com/macros/s/AKfycbwidiFlxGdt5TC03fO1pqJTibAgpQ0sQrfn5eWcWSvxrFUp7_a0owvN2-CWC7sTR5v1CQ/exec"  -- hasil Deploy (berakhiran /exec)
local BUY_INFO = "Beli key: WhatsApp 0895385590527"             -- teks info beli key
local KEY_FILE = "MasensDev_Key.txt"                             -- key tersimpan, jadi tidak ketik ulang

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Analytics = game:GetService("RbxAnalyticsService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- fungsi request milik executor
local req = (syn and syn.request) or (http and http.request) or http_request or request

-- ID device
local function getHWID()
	local ok, id = pcall(function() return Analytics:GetClientId() end)
	if ok and type(id) == "string" and id ~= "" then return id end
	if type(gethwid) == "function" then
		local ok2, h = pcall(gethwid)
		if ok2 and h then return tostring(h) end
	end
	return nil
end

local function verify(key)
	if not req then return false, "Executor kamu tidak mendukung request HTTP" end
	local hwid = getHWID()
	if not hwid then return false, "Gagal membaca ID device" end
	local url = string.format("%s?key=%s&hwid=%s&user=%s", API_URL,
		HttpService:UrlEncode(key), HttpService:UrlEncode(hwid), HttpService:UrlEncode(player.Name))
	local ok, res = pcall(req, { Url = url, Method = "GET" })
	if not ok or not res or not res.Body then return false, "Server tidak bisa dihubungi" end
	local ok2, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
	if not ok2 or type(data) ~= "table" then return false, "Respon server tidak valid" end
	if data.ok and type(data.script) == "string" then return true, data.script end
	return false, data.msg or "Key ditolak"
end

local function runScript(code)
	local fn, err = loadstring(code)
	if not fn then warn("[MasensDev] Gagal load script: " .. tostring(err)) return false end
	task.spawn(fn)
	return true
end

-- GUI input key
local old = playerGui:FindFirstChild("MasensKeyGui")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset, gui.DisplayOrder = "MasensKeyGui", false, true, 150
gui.Parent = playerGui

local function new(class, props, parent)
	local i = Instance.new(class)
	for k, v in pairs(props) do i[k] = v end
	i.Parent = parent
	return i
end
local GOLD = Color3.fromRGB(212, 175, 55)

local box = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(340, 230),
	BackgroundColor3 = Color3.fromRGB(24, 22, 34), BorderSizePixel = 0,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 12) }, box)
new("UIStroke", { Color = GOLD, Thickness = 2 }, box)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(34, 28, 52), Color3.fromRGB(14, 14, 20)) }, box)
new("UIScale", { Scale = math.clamp((workspace.CurrentCamera.ViewportSize.X - 20) / 340, 0.5, 1) }, box)

new("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 12), Size = UDim2.new(1, 0, 0, 30),
	Text = "MASENSDEV PREMIUM", Font = Enum.Font.GothamBlack, TextSize = 20, TextColor3 = GOLD,
}, box)
new("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 42), Size = UDim2.new(1, 0, 0, 18),
	Text = "Masukkan key premium kamu", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Color3.fromRGB(180, 175, 200),
}, box)

local input = new("TextBox", {
	Position = UDim2.fromOffset(20, 76), Size = UDim2.new(1, -40, 0, 34), BackgroundColor3 = Color3.fromRGB(40, 43, 54),
	BorderSizePixel = 0, Text = "", PlaceholderText = "MSD-XXXX-XXXX-XXXX", PlaceholderColor3 = Color3.fromRGB(130, 135, 150),
	Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.new(1, 1, 1), ClearTextOnFocus = false,
}, box)
new("UICorner", { CornerRadius = UDim.new(0, 6) }, input)

local btn = new("TextButton", {
	Position = UDim2.fromOffset(20, 122), Size = UDim2.new(1, -40, 0, 34), BackgroundColor3 = Color3.fromRGB(184, 134, 11),
	BorderSizePixel = 0, Text = "VERIFIKASI", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.new(1, 1, 1),
}, box)
new("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)

local status = new("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 164), Size = UDim2.new(1, -40, 0, 20),
	Text = "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(255, 120, 120),
}, box)
new("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 192), Size = UDim2.new(1, -40, 0, 20),
	Text = BUY_INFO, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(150, 150, 170),
}, box)

local busy = false
local function attempt(key)
	if busy then return end
	key = string.match(key or "", "^%s*(.-)%s*$")
	if key == "" then status.Text = "Key belum diisi" return end
	busy = true
	status.TextColor3 = Color3.fromRGB(240, 215, 140)
	status.Text = "Memeriksa key..."
	local ok, result = verify(key)
	if ok then
		pcall(function() if writefile then writefile(KEY_FILE, key) end end)
		status.TextColor3 = Color3.fromRGB(120, 230, 150)
		status.Text = "Key valid! Memuat script..."
		task.wait(0.6)
		gui:Destroy()
		runScript(result)
	else
		status.TextColor3 = Color3.fromRGB(255, 120, 120)
		status.Text = result
		busy = false
	end
end

btn.Activated:Connect(function() attempt(input.Text) end)
input.FocusLost:Connect(function(enter) if enter then attempt(input.Text) end end)

-- coba key yang tersimpan otomatis
task.spawn(function()
	local saved
	pcall(function() if isfile and isfile(KEY_FILE) then saved = readfile(KEY_FILE) end end)
	if saved and saved ~= "" then
		input.Text = saved
		attempt(saved)
	end
end)
