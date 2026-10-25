--[[
	MasensDev Premium - Loader (Premium key + Free 6 jam, kunci device)
	File INI yang boleh publik (GitHub). Script utama TIDAK ada di sini.

	loadstring(game:HttpGet("https://raw.githubusercontent.com/USERNAME/REPO/main/Loader.lua"))()
]]

local API_URL  = "https://script.google.com/macros/s/AKfycbw8GGnGrdgNAhK_aIb1A83gDX1YPF1q2q2IS9n8wEy9UhdqWc-1ST3fspKxzmx9j_hjeQ/exec"
local BUY_INFO = "Beli key premium: WhatsApp 0895385590527"
local KEY_FILE = "MasensDev_Key.txt"

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Analytics = game:GetService("RbxAnalyticsService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local req = (syn and syn.request) or (http and http.request) or http_request or request

local function getHWID()
	local ok, id = pcall(function() return Analytics:GetClientId() end)
	if ok and type(id) == "string" and id ~= "" then return id end
	if type(gethwid) == "function" then
		local ok2, h = pcall(gethwid)
		if ok2 and h then return tostring(h) end
	end
	return nil
end

-- params: { key = "..." } untuk premium, { action = "free" } untuk free
local function call(params)
	if not req then return false, "Executor kamu tidak mendukung request HTTP" end
	local hwid = getHWID()
	if not hwid then return false, "Gagal membaca ID device" end
	params.hwid, params.user = hwid, player.Name
	local parts = {}
	for k, v in pairs(params) do
		table.insert(parts, k .. "=" .. HttpService:UrlEncode(tostring(v)))
	end
	local ok, res = pcall(req, { Url = API_URL .. "?" .. table.concat(parts, "&"), Method = "GET" })
	if not ok or not res or not res.Body then return false, "Server tidak bisa dihubungi" end
	local ok2, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
	if not ok2 or type(data) ~= "table" then return false, "Respon server tidak valid" end
	if data.ok and type(data.script) == "string" then return true, data end
	return false, data.msg or "Akses ditolak"
end

local function runScript(data)
	local g = (getgenv and getgenv()) or _G
	g.MasensAccess = { tier = data.tier or "premium", remain = tonumber(data.remain) or 0 }
	local fn, err = loadstring(data.script)
	if not fn then warn("[MasensDev] Gagal load script: " .. tostring(err)) return false end
	task.spawn(fn)
	return true
end

-- GUI
for _, parent in ipairs({ playerGui }) do
	local old = parent:FindFirstChild("MasensKeyGui")
	if old then old:Destroy() end
end
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset, gui.DisplayOrder = "MasensKeyGui", false, true, 150
gui.Parent = playerGui

local function new(class, props, parent)
	local i = Instance.new(class)
	for k, v in pairs(props) do i[k] = v end
	i.Parent = parent
	return i
end
local RED, GOLD = Color3.fromRGB(225, 29, 72), Color3.fromRGB(245, 180, 80)

local box = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(340, 282),
	BackgroundColor3 = Color3.fromRGB(17, 17, 23), BorderSizePixel = 0,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 14) }, box)
new("UIStroke", { Color = Color3.fromRGB(44, 44, 58), Thickness = 1 }, box)
local topLine = new("Frame", { Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, box)
new("UIGradient", { Color = ColorSequence.new(RED, GOLD) }, topLine)
local cam = workspace.CurrentCamera
new("UIScale", { Scale = math.clamp(math.min((cam.ViewportSize.X - 20) / 340, (cam.ViewportSize.Y - 20) / 282), 0.5, 1) }, box)

local title = new("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 14), Size = UDim2.new(1, 0, 0, 28),
	Text = "MASENSDEV", Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = Color3.new(1, 1, 1),
}, box)
new("UIGradient", { Color = ColorSequence.new(RED, GOLD) }, title)
new("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 42), Size = UDim2.new(1, 0, 0, 18),
	Text = "Masukkan key premium, atau coba gratis 6 jam", Font = Enum.Font.Gotham, TextSize = 12,
	TextColor3 = Color3.fromRGB(140, 140, 158),
}, box)

local input = new("TextBox", {
	Position = UDim2.fromOffset(20, 74), Size = UDim2.new(1, -40, 0, 34), BackgroundColor3 = Color3.fromRGB(25, 25, 33),
	BorderSizePixel = 0, Text = "", PlaceholderText = "MSD-XXXX-XXXX-XXXX", PlaceholderColor3 = Color3.fromRGB(110, 110, 128),
	Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.new(1, 1, 1), ClearTextOnFocus = false,
}, box)
new("UICorner", { CornerRadius = UDim.new(0, 8) }, input)

local function mkBtn(text, y, color)
	local b = new("TextButton", {
		Position = UDim2.fromOffset(20, y), Size = UDim2.new(1, -40, 0, 34), BackgroundColor3 = color,
		BorderSizePixel = 0, Text = text, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = true,
	}, box)
	new("UICorner", { CornerRadius = UDim.new(0, 8) }, b)
	return b
end
local btn = mkBtn("VERIFIKASI KEY PREMIUM", 118, RED)
local freeBtn = mkBtn("COBA GRATIS 6 JAM", 160, Color3.fromRGB(44, 44, 58))
freeBtn.TextColor3 = GOLD

local status = new("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 204), Size = UDim2.new(1, -40, 0, 34),
	Text = "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(255, 110, 130), TextWrapped = true,
}, box)
new("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 248), Size = UDim2.new(1, -40, 0, 20),
	Text = BUY_INFO, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(140, 140, 158),
}, box)

local busy = false
local function attempt(params, isPremium, key)
	if busy then return end
	busy = true
	status.TextColor3 = GOLD
	status.Text = "Memeriksa akses..."
	local ok, result = call(params)
	if ok then
		if isPremium then pcall(function() if writefile then writefile(KEY_FILE, key) end end) end
		status.TextColor3 = Color3.fromRGB(52, 211, 153)
		status.Text = (result.tier == "free") and "Akses FREE aktif! Memuat script..." or "Key valid! Memuat script..."
		task.wait(0.6)
		gui:Destroy()
		runScript(result)
	else
		status.TextColor3 = Color3.fromRGB(255, 110, 130)
		status.Text = result
		busy = false
	end
end

local function tryKey()
	local key = string.match(input.Text or "", "^%s*(.-)%s*$")
	if key == "" then status.TextColor3 = Color3.fromRGB(255, 110, 130) status.Text = "Key belum diisi" return end
	attempt({ key = key }, true, key)
end
btn.Activated:Connect(tryKey)
input.FocusLost:Connect(function(enter) if enter then tryKey() end end)
freeBtn.Activated:Connect(function() attempt({ action = "free" }, false) end)

-- key premium tersimpan: coba otomatis
task.spawn(function()
	local saved
	pcall(function() if isfile and isfile(KEY_FILE) then saved = readfile(KEY_FILE) end end)
	saved = saved and string.match(saved, "^%s*(.-)%s*$")
	if saved and saved ~= "" then
		input.Text = saved
		attempt({ key = saved }, true, saved)
	end
end)
