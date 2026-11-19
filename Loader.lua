--[[
	MasensDev Key System - Loader.lua
	Mendukung:
	  - Verifikasi Key Premium (MSD-...) & Free Key 6 Jam (FREE-...)
	  - Tombol Get Free Key (salin link Linkvertise / Apps Script)
	  - Tombol Harga Key (pilih paket + salin link order WhatsApp otomatis)
]]

local WEB_APP_URL = "https://script.google.com/macros/s/AKfycbw8GGnGrdgNAhK_aIb1A83gDX1YPF1q2q2IS9n8wEy9UhdqWc-1ST3fspKxzmx9j_hjeQ/exec"
local WHATSAPP_NUMBER = "62895385590527" -- Ganti dengan nomor WA kamu (awalan 62, tanpa + atau spasi)

---------------------------------------------------------
-- SERVICES & ENVIRONMENT
---------------------------------------------------------
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local genv = (getgenv and getgenv()) or _G

local PRICE_LIST = {
	{
		durasi = "1 Bulan",
		harga = "Rp 5.000",
		tag = "",
		chat = "Halo MasensDev, saya mau pesan Key Premium yang 1 Bulan (Rp 5.000). Username Roblox: " .. player.Name,
	},
	{
		durasi = "3 Bulan",
		harga = "Rp 10.000",
		tag = "",
		chat = "Halo MasensDev, saya mau pesan Key Premium yang 3 Bulan (Rp 10.000). Username Roblox: " .. player.Name,
	},
	{
		durasi = "6 Bulan",
		harga = "Rp 15.000",
		tag = "",
		chat = "Halo MasensDev, saya mau pesan Key Premium yang 6 Bulan (Rp 15.000). Username Roblox: " .. player.Name,
	},
	{
		durasi = "1 Tahun",
		harga = "Rp 20.000",
		tag = "HEMAT",
		chat = "Halo MasensDev, saya mau pesan Key Premium paket 1 Tahun - Hemat (Rp 20.000). Username Roblox: " .. player.Name,
	},
	{
		durasi = "Permanent",
		harga = "Rp 30.000",
		tag = "BEST VALUE",
		chat = "Halo MasensDev, saya mau pesan Key Premium paket Permanent - Best Value (Rp 30.000). Username Roblox: " .. player.Name,
	},
}

local MainParent = playerGui
do
	local ok, hui = pcall(function() return gethui and gethui() end)
	if ok and typeof(hui) == "Instance" then MainParent = hui end
end
local old = MainParent:FindFirstChild("MasensLoader") or playerGui:FindFirstChild("MasensLoader")
if old then old:Destroy() end

---------------------------------------------------------
-- HELPER FUNGSI EXECUTOR (HWID, CLIPBOARD, FILE, HTTP)
---------------------------------------------------------
local function getHWID()
	local ok, id = pcall(function() return RbxAnalyticsService:GetClientId() end)
	if ok and id and id ~= "" then return tostring(id) end
	return "USER_" .. tostring(player.UserId)
end

local function copyToClipboard(text)
	local fn = (genv and (genv.setclipboard or genv.toclipboard)) or setclipboard or toclipboard
	if type(fn) == "function" then
		return pcall(fn, text)
	end
	return false
end

local KEY_FILE = "MasensDev_LastKey.txt"
local env = getfenv()
local fsWrite, fsRead, fsIsFile = env["writefile"], env["readfile"], env["isfile"]

local function loadSavedKey()
	if type(fsIsFile) == "function" and type(fsRead) == "function" then
		local ok, data = pcall(function()
			return fsIsFile(KEY_FILE) and fsRead(KEY_FILE) or ""
		end)
		if ok and type(data) == "string" then
			return string.match(data, "^%s*(.-)%s*$")
		end
	end
	return ""
end

local function saveKeyToFile(k)
	if type(fsWrite) == "function" then
		pcall(fsWrite, KEY_FILE, k)
	end
end

local function httpGet(url)
	local ok, res = pcall(function()
		return game:HttpGet(url)
	end)
	if ok and type(res) == "string" and res ~= "" then
		return true, res
	end
	local req = (genv and (genv.request or genv.http_request)) or request or http_request or (syn and syn.request)
	if type(req) == "function" then
		local ok2, r2 = pcall(function()
			return req({ Url = url, Method = "GET" })
		end)
		if ok2 and type(r2) == "table" and r2.Body then
			return true, r2.Body
		end
	end
	return false, tostring(res)
end

---------------------------------------------------------
-- WARNA & HELPER UI
---------------------------------------------------------
local ACC1 = Color3.fromRGB(225, 29, 72)
local ACC2 = Color3.fromRGB(245, 180, 80)
local C = {
	bg = Color3.fromRGB(11, 11, 15),
	panel = Color3.fromRGB(17, 17, 23),
	field = Color3.fromRGB(25, 25, 33),
	rowSelected = Color3.fromRGB(36, 22, 30),
	stroke = Color3.fromRGB(44, 44, 58),
	dim = Color3.fromRGB(145, 145, 165),
	text = Color3.fromRGB(240, 240, 246),
	green = Color3.fromRGB(22, 163, 120),
	orange = Color3.fromRGB(217, 119, 6),
	teal = Color3.fromRGB(30, 130, 160),
	gray = Color3.fromRGB(44, 44, 58),
	err = Color3.fromRGB(255, 110, 130),
}

local function new(cls, props, parent)
	local inst = Instance.new(cls)
	for k, v in pairs(props or {}) do inst[k] = v end
	inst.Parent = parent
	return inst
end

local function corner(p, r)
	return new("UICorner", { CornerRadius = UDim.new(0, r or 8) }, p)
end

local function stroke(p, col, th)
	return new("UIStroke", {
		Color = col or C.stroke,
		Thickness = th or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, p)
end

local function mkBtn(parent, text, pos, size, bgCol, textSize)
	local b = new("TextButton", {
		Position = pos, Size = size, BackgroundColor3 = bgCol, BorderSizePixel = 0,
		Text = text, Font = Enum.Font.GothamBold, TextSize = textSize or 13,
		TextColor3 = Color3.new(1, 1, 1), AutoButtonColor = false,
	}, parent)
	corner(b, 8)
	local st = stroke(b, Color3.new(1, 1, 1), 1)
	st.Transparency = 0.88
	b.MouseEnter:Connect(function() TweenService:Create(st, TweenInfo.new(0.15), { Transparency = 0.45 }):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(st, TweenInfo.new(0.15), { Transparency = 0.88 }):Play() end)
	return b
end

---------------------------------------------------------
-- GUI LOADER UTAMA
---------------------------------------------------------
local gui = new("ScreenGui", {
	Name = "MasensLoader", ResetOnSpawn = false, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100,
}, MainParent)

local main = new("Frame", {
	Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(420, 275), BackgroundColor3 = C.bg, BorderSizePixel = 0,
}, gui)
corner(main, 14)
stroke(main, C.stroke, 1)

-- Skala otomatis untuk layar HP / PC
local uiScale = new("UIScale", {}, main)
local function fitScale()
	local cam = Workspace.CurrentCamera
	if not cam then return end
	local vp = cam.ViewportSize
	local fit = math.min((vp.X - 24) / 420, (vp.Y - 24) / 390)
	uiScale.Scale = math.clamp(fit, 0.55, 1.1)
end
fitScale()
if Workspace.CurrentCamera then
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitScale)
end

-- Header
local header = new("Frame", {
	Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = C.panel, BorderSizePixel = 0,
}, main)
corner(header, 14)
new("Frame", {
	Position = UDim2.new(0, 0, 1, -14), Size = UDim2.new(1, 0, 0, 14),
	BackgroundColor3 = C.panel, BorderSizePixel = 0,
}, header)
local topLine = new("Frame", {
	Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 4,
}, main)
new("UIGradient", { Color = ColorSequence.new(ACC1, ACC2) }, topLine)
new("Frame", {
	Position = UDim2.new(0, 0, 0, 48), Size = UDim2.new(1, 0, 0, 1),
	BackgroundColor3 = C.stroke, BorderSizePixel = 0, ZIndex = 3,
}, main)

local logo = new("Frame", {
	Position = UDim2.fromOffset(14, 11), Size = UDim2.fromOffset(26, 26),
	BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3,
}, header)
corner(logo, 7)
new("UIGradient", { Color = ColorSequence.new(ACC1, ACC2), Rotation = 45 }, logo)
new("TextLabel", {
	Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "M",
	Font = Enum.Font.GothamBlack, TextSize = 15, TextColor3 = Color3.new(1, 1, 1), ZIndex = 4,
}, logo)

new("TextLabel", {
	Position = UDim2.fromOffset(48, 7), Size = UDim2.fromOffset(260, 18), BackgroundTransparency = 1,
	Text = "MASENSDEV", Font = Enum.Font.GothamBlack, TextSize = 15,
	TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3,
}, header)
new("TextLabel", {
	Position = UDim2.fromOffset(48, 25), Size = UDim2.fromOffset(280, 14), BackgroundTransparency = 1,
	Text = "Key Verification  •  Checkpoint Tools", Font = Enum.Font.Gotham, TextSize = 11,
	TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3,
}, header)

local closeBtn = mkBtn(header, "X", UDim2.new(1, -38, 0.5, -14), UDim2.fromOffset(28, 28), C.field, 13)
closeBtn.ZIndex = 4
closeBtn.Activated:Connect(function() gui:Destroy() end)

-- Drag window
do
	local dragging, dragStart, startPos, dragType
	header.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragType = inp.UserInputType
			dragStart = inp.Position
			startPos = main.Position
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if dragging and inp.UserInputType == dragType then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			local d = inp.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

---------------------------------------------------------
-- HALAMAN 1: INPUT KEY
---------------------------------------------------------
local loginPage = new("Frame", {
	Position = UDim2.fromOffset(0, 49), Size = UDim2.new(1, 0, 1, -49),
	BackgroundTransparency = 1,
}, main)

new("TextLabel", {
	Position = UDim2.fromOffset(20, 14), Size = UDim2.new(1, -40, 0, 16), BackgroundTransparency = 1,
	Text = "Masukkan Key (Premium MSD-... atau Free Key FREE-...)",
	Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Left,
}, loginPage)

local keyBox = new("TextBox", {
	Position = UDim2.fromOffset(20, 34), Size = UDim2.new(1, -40, 0, 38),
	BackgroundColor3 = C.field, BorderSizePixel = 0,
	Text = loadSavedKey(), PlaceholderText = "Tempel key kamu di sini...",
	PlaceholderColor3 = Color3.fromRGB(105, 105, 125),
	Font = Enum.Font.Code, TextSize = 13, TextColor3 = ACC2,
	ClearTextOnFocus = false, ClipsDescendants = true,
}, loginPage)
corner(keyBox, 8)
local keyStroke = stroke(keyBox, C.stroke, 1)
keyBox.Focused:Connect(function() TweenService:Create(keyStroke, TweenInfo.new(0.15), { Color = ACC1 }):Play() end)
keyBox.FocusLost:Connect(function() TweenService:Create(keyStroke, TweenInfo.new(0.15), { Color = C.stroke }):Play() end)

local verifyBtn = mkBtn(loginPage, "VERIFIKASI & JALANKAN", UDim2.fromOffset(20, 82), UDim2.new(1, -40, 0, 38), ACC1, 13)

local halfW = (420 - 40 - 10) / 2
local freeKeyBtn = mkBtn(loginPage, "Get Free Key", UDim2.fromOffset(20, 128), UDim2.fromOffset(halfW, 34), C.orange, 12)
local priceListBtn = mkBtn(loginPage, "Harga Key", UDim2.fromOffset(20 + halfW + 10, 128), UDim2.fromOffset(halfW, 34), C.teal, 12)

local statusLbl = new("TextLabel", {
	Position = UDim2.fromOffset(20, 170), Size = UDim2.new(1, -40, 0, 44), BackgroundTransparency = 1,
	Text = "Belum punya key? Klik 'Get Free Key' (gratis 6 jam) atau cek 'Harga Key'.",
	Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.dim,
	TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
}, loginPage)

local function setStatus(msg, isErr)
	statusLbl.Text = msg
	statusLbl.TextColor3 = isErr and C.err or C.text
end

---------------------------------------------------------
-- HALAMAN 2: PILIH PAKET HARGA & LINK ORDER WHATSAPP
---------------------------------------------------------
local pricePage = new("Frame", {
	Position = UDim2.fromOffset(0, 49), Size = UDim2.new(1, 0, 1, -49),
	BackgroundTransparency = 1, Visible = false,
}, main)

new("TextLabel", {
	Position = UDim2.fromOffset(20, 10), Size = UDim2.new(1, -120, 0, 20), BackgroundTransparency = 1,
	Text = "PILIH PAKET KEY PREMIUM", Font = Enum.Font.GothamBlack, TextSize = 13,
	TextColor3 = ACC2, TextXAlignment = Enum.TextXAlignment.Left,
}, pricePage)

local backBtn = mkBtn(pricePage, "< Kembali", UDim2.new(1, -104, 0, 8), UDim2.fromOffset(84, 24), C.gray, 11)

local listContainer = new("Frame", {
	Position = UDim2.fromOffset(20, 38), Size = UDim2.new(1, -40, 0, 186),
	BackgroundTransparency = 1,
}, pricePage)
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }, listContainer)

local selectedIndex = 1 -- default memilih paket pertama (1 Bulan)
local rowWidgets = {}

local copyOrderBtn = mkBtn(pricePage, "", UDim2.fromOffset(20, 264), UDim2.new(1, -40, 0, 36), C.green, 12)

local orderNote = new("TextLabel", {
	Position = UDim2.fromOffset(20, 304), Size = UDim2.new(1, -40, 0, 26), BackgroundTransparency = 1,
	Text = "Klik paket di atas, lalu tekan tombol hijau untuk menyalin link WhatsApp.",
	Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.dim,
	TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
}, pricePage)

local function updatePriceSelection()
	local sel = PRICE_LIST[selectedIndex]
	for idx, w in ipairs(rowWidgets) do
		local active = (idx == selectedIndex)
		w.btn.BackgroundColor3 = active and C.rowSelected or C.field
		w.stroke.Color = active and ACC2 or C.stroke
		w.stroke.Thickness = active and 1.5 or 1
		w.radio.Text = active and "●" or "○"
		w.radio.TextColor3 = active and ACC2 or C.dim
	end
	copyOrderBtn.Text = string.format("Salin Link Order WA  (%s - %s)", sel.durasi, sel.harga)
end

for i, item in ipairs(PRICE_LIST) do
	local isBest = (item.tag == "BEST VALUE")
	local rowBtn = new("TextButton", {
		LayoutOrder = i, Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = C.field, BorderSizePixel = 0,
		Text = "", AutoButtonColor = false,
	}, listContainer)
	corner(rowBtn, 7)
	local rowStroke = stroke(rowBtn, C.stroke, 1)

	local radioLbl = new("TextLabel", {
		Position = UDim2.fromOffset(10, 0), Size = UDim2.fromOffset(18, 32), BackgroundTransparency = 1,
		Text = "○", Font = Enum.Font.GothamBold, TextSize = 13,
		TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Center,
	}, rowBtn)

	new("TextLabel", {
		Position = UDim2.fromOffset(30, 0), Size = UDim2.fromOffset(105, 32), BackgroundTransparency = 1,
		Text = item.durasi, Font = Enum.Font.GothamBold, TextSize = 13,
		TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
	}, rowBtn)

	if item.tag ~= "" then
		local tagLbl = new("TextLabel", {
			Position = UDim2.fromOffset(128, 7), Size = UDim2.fromOffset(86, 18),
			BackgroundColor3 = isBest and ACC2 or ACC1, BorderSizePixel = 0,
			Text = item.tag, Font = Enum.Font.GothamBlack, TextSize = 9,
			TextColor3 = isBest and Color3.fromRGB(20, 15, 10) or Color3.new(1, 1, 1),
		}, rowBtn)
		corner(tagLbl, 4)
	end

	new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 0), Size = UDim2.fromOffset(115, 32),
		BackgroundTransparency = 1, Text = item.harga, Font = Enum.Font.GothamBlack, TextSize = 13,
		TextColor3 = ACC2, TextXAlignment = Enum.TextXAlignment.Right,
	}, rowBtn)

	rowWidgets[i] = { btn = rowBtn, stroke = rowStroke, radio = radioLbl }

	rowBtn.Activated:Connect(function()
		selectedIndex = i
		updatePriceSelection()
		orderNote.Text = "Paket " .. item.durasi .. " (" .. item.harga .. ") dipilih. Klik tombol hijau untuk salin link WA."
		orderNote.TextColor3 = C.text
	end)
end

updatePriceSelection()

new("TextLabel", {
	Position = UDim2.fromOffset(20, 230), Size = UDim2.new(1, -40, 0, 28), BackgroundTransparency = 1,
	Text = "Benefit Premium: Tanpa iklan Linkvertise & Unlimited slot penyimpanan Config.",
	Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.dim,
	TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
}, pricePage)

-- Navigasi buka/tutup halaman harga
local function showPricePage(show)
	loginPage.Visible = not show
	pricePage.Visible = show
	local targetH = show and 386 or 275
	TweenService:Create(main, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(420, targetH),
	}):Play()
end

priceListBtn.Activated:Connect(function() showPricePage(true) end)
backBtn.Activated:Connect(function() showPricePage(false) end)

copyOrderBtn.Activated:Connect(function()
	local sel = PRICE_LIST[selectedIndex]
	local cleanPhone = string.gsub(WHATSAPP_NUMBER, "%D", "")
	local waUrl = "https://wa.me/" .. cleanPhone .. "?text=" .. HttpService:UrlEncode(sel.chat)

	local ok = copyToClipboard(waUrl)
	if ok then
		copyOrderBtn.Text = "LINK WA TERSALIN! TEMPEL DI BROWSER"
		orderNote.Text = "Link WA paket " .. sel.durasi .. " tersalin! Buka Chrome/Browser lalu tempel (Paste)."
		orderNote.TextColor3 = ACC2
	else
		-- Cadangan jika executor tidak mendukung setclipboard
		showPricePage(false)
		keyBox.Text = waUrl
		setStatus("Salin link WhatsApp di kotak atas lalu buka di Chrome/Browser.")
	end

	task.delay(3, function()
		if copyOrderBtn.Parent then
			updatePriceSelection()
			orderNote.TextColor3 = C.dim
		end
	end)
end)

---------------------------------------------------------
-- LOGIKA TOMBOL GET FREE KEY & VERIFIKASI
---------------------------------------------------------
freeKeyBtn.Activated:Connect(function()
	if WEB_APP_URL == "" or string.find(WEB_APP_URL, "TEMPEL_URL", 1, true) then
		setStatus("WEB_APP_URL belum diisi di Loader.lua!", true)
		return
	end
	local ok = copyToClipboard(WEB_APP_URL)
	if ok then
		setStatus("Link Get Free Key disalin! Buka browser & tempel untuk mengambil key gratis 6 jam.")
	else
		keyBox.Text = WEB_APP_URL
		setStatus("Salin link di kotak atas lalu buka di browser untuk mengambil Free Key.")
	end
end)

local busy = false
local function verifyKey()
	if busy then return end
	local k = string.match(keyBox.Text or "", "^%s*(.-)%s*$")
	if k == "" then
		setStatus("Masukkan key terlebih dahulu!", true)
		return
	end
	if WEB_APP_URL == "" or string.find(WEB_APP_URL, "TEMPEL_URL", 1, true) then
		setStatus("WEB_APP_URL belum diisi di Loader.lua!", true)
		return
	end

	busy = true
	verifyBtn.Text = "MEMVERIFIKASI..."
	setStatus("Menghubungkan ke server...")

	task.spawn(function()
		local url = string.format(
			"%s?key=%s&hwid=%s&user=%s",
			WEB_APP_URL,
			HttpService:UrlEncode(k),
			HttpService:UrlEncode(getHWID()),
			HttpService:UrlEncode(player.Name)
		)

		local ok, raw = httpGet(url)
		if not ok then
			setStatus("Gagal terhubung ke server: " .. tostring(raw), true)
			verifyBtn.Text = "VERIFIKASI & JALANKAN"
			busy = false
			return
		end

		local decOk, data = pcall(function() return HttpService:JSONDecode(raw) end)
		if not decOk or type(data) ~= "table" then
			setStatus("Respons server tidak valid. Pastikan URL /exec benar.", true)
			verifyBtn.Text = "VERIFIKASI & JALANKAN"
			busy = false
			return
		end

		if not data.ok then
			setStatus(tostring(data.msg or "Key ditolak server."), true)
			verifyBtn.Text = "VERIFIKASI & JALANKAN"
			busy = false
			return
		end

		-- Simpan key agar tidak perlu ketik ulang
		saveKeyToFile(k)

		-- Kirim info tier ("free" / "premium") dan sisa waktu ke skrip utama
		genv.MasensAccess = {
			tier = data.tier or "free",
			remain = tonumber(data.remain) or 0,
		}

		setStatus("Key valid! Memuat MasensDev...")
		local fn, loadErr = loadstring(tostring(data.script or ""))
		if not fn then
			setStatus("Gagal menjalankan script: " .. tostring(loadErr), true)
			verifyBtn.Text = "VERIFIKASI & JALANKAN"
			busy = false
			return
		end

		gui:Destroy()
		task.spawn(fn)
	end)
end

verifyBtn.Activated:Connect(verifyKey)
keyBox.FocusLost:Connect(function(enter)
	if enter then verifyKey() end
end)
