-- 🔐 MIKU SCRIPTS AUTO JOIN SCRIPT - SISTEMA DE VERIFICACIÓN DE KEYS
-- Este script requiere una key válida y verificación HWID
-- Uso: _G.KEY = "tu_key_aqui"; loadstring(game:HttpGet("URL_DEL_SCRIPT"))()

-- ⚠️ VERIFICACIÓN DE KEY OBLIGATORIA
if not _G.KEY or type(_G.KEY) ~= "string" or _G.KEY == "" then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "❌ ACCESO DENEGADO";
        Text = "Debes establecer _G.KEY = 'tu_key' antes de ejecutar";
        Duration = 10;
    })
    error("❌ Key requerida. Uso: _G.KEY = 'tu_key'; loadstring(game:HttpGet('URL'))()")  
    return
end

-- CONFIG PRINCIPAL  
local API_URL = "https://miku-scripts.onrender.com/api/roblox-script"
local KEY_VALIDATION_URL = "https://miku-scripts.onrender.com/api/key-validation"
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

-- Detectar función http_request
local request = http_request or syn and syn.request or fluxus and fluxus.request or krnl and krnl.request or getgenv().request
if not request then
    StarterGui:SetCore("SendNotification", {
        Title = "❌ EXECUTOR NO COMPATIBLE";
        Text = "Tu executor no soporta http_request";
        Duration = 10;
    })
    return
end

-- Obtener HWID del dispositivo
local hwid = "unknown_hwid"
pcall(function()
    hwid = game:GetService("RbxAnalyticsService"):GetClientId()
end)

-- 🔐 FUNCIÓN DE VERIFICACIÓN DE KEY Y HWID
local function validateKeyAndHWID()
    StarterGui:SetCore("SendNotification", {
        Title = "🔄 VERIFICANDO ACCESO";
        Text = "Validando key y dispositivo...";
        Duration = 3;
    })
    
    -- Realizar solicitud de validación con POST method y JSON body (más seguro)
    local validationData = {
        key = _G.KEY,
        hwid = hwid
    }
    local response = request({
        Url = KEY_VALIDATION_URL,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode(validationData)
    })
    
    if not response or response.StatusCode ~= 200 then
        StarterGui:SetCore("SendNotification", {
            Title = "❌ ERROR DE CONEXIÓN";
            Text = "No se pudo verificar la key. Código: " .. (response and response.StatusCode or "???");
            Duration = 10;
        })
        return false, "Error de conexión al servidor de validación"
    end
    
    local validationResult = HttpService:JSONDecode(response.Body)
    
    if not validationResult.valid then
        local errorMsg = validationResult.message or "Key inválida o dispositivo no autorizado"
        StarterGui:SetCore("SendNotification", {
            Title = "❌ ACCESO DENEGADO";
            Text = errorMsg;
            Duration = 15;
        })
        return false, errorMsg
    end
    
    -- Verificación exitosa
    StarterGui:SetCore("SendNotification", {
        Title = "✅ ACCESO AUTORIZADO";
        Text = "Key válida. Iniciando Auto Join...";
        Duration = 5;
    })
    
    return true, "Acceso autorizado"
end

-- 🔐 VERIFICAR KEY ANTES DE CONTINUAR
local isValid, validationMessage = validateKeyAndHWID()
if not isValid then
    error("❌ Verificación fallida: " .. validationMessage)
    return
end

-- GUI seguro (funciona en PC y Celular)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoJoinUI"
pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

-- MAIN FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 180)
MainFrame.Position = UDim2.new(0.5, -150, 0.4, -90)
MainFrame.BackgroundColor3 = Color3.fromRGB(50, 200, 255)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(100, 230, 255)
Title.Text = "🔐 Miku Scripts [VERIFICADO]"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

-- Funciones utilitarias
local function formatMoney(num)
    if num >= 1e9 then
        return string.format("%.1fB", num / 1e9)
    elseif num >= 1e6 then
        return string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.1fK", num / 1e3)
    end
    return tostring(num)
end

local function parseInput(str)
    local num = tonumber(str)
    if num then
        return math.max(num * 1000000, 1e6)
    end
    return nil
end

-- ✅ VERIFICACIÓN EXITOSA - CONTINUANDO CON EL SCRIPT
-- Key verificada: " .. string.sub(_G.KEY, 1, 8) .. "..."
-- HWID autorizado: " .. string.sub(hwid, 1, 8) .. "..."

local cfgFile = "autojoin_"..hwid..".json"

local function loadConfig()
    if isfile and isfile(cfgFile) then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(cfgFile))
        end)
        if ok and type(data) == "table" then
            return data
        end
    end
    return { MinMS = 1000000 }
end

local function saveConfig(cfg)
    if writefile then
        writefile(cfgFile, HttpService:JSONEncode(cfg))
    end
end

local config = loadConfig()
local MinMS = config.MinMS or 1000000
local AutoJoinEnabled = false

-- Botón toggle
local Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.new(1, -20, 0, 35)
Toggle.Position = UDim2.new(0, 10, 0, 50)
Toggle.BackgroundColor3 = Color3.fromRGB(100, 230, 255)
Toggle.Text = "Auto Join: OFF"
Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
Toggle.Font = Enum.Font.GothamBold
Toggle.TextSize = 16
Toggle.Parent = MainFrame

Toggle.MouseButton1Click:Connect(function()
    AutoJoinEnabled = not AutoJoinEnabled
    Toggle.Text = "Auto Join: " .. (AutoJoinEnabled and "ON" or "OFF")
    Toggle.TextColor3 = AutoJoinEnabled and Color3.fromRGB(0, 100, 200) or Color3.fromRGB(255, 255, 255)
end)

-- Label de mínimo
local MinLabel = Instance.new("TextLabel")
MinLabel.Size = UDim2.new(1, -20, 0, 25)
MinLabel.Position = UDim2.new(0, 10, 0, 95)
MinLabel.BackgroundTransparency = 1
MinLabel.Text = "Min M/s: " .. formatMoney(MinMS)
MinLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
MinLabel.Font = Enum.Font.Gotham
MinLabel.TextSize = 14
MinLabel.Parent = MainFrame

-- Caja de texto
local MinBox = Instance.new("TextBox")
MinBox.Size = UDim2.new(1, -20, 0, 25)
MinBox.Position = UDim2.new(0, 10, 0, 120)
MinBox.BackgroundColor3 = Color3.fromRGB(150, 230, 255)
MinBox.Text = tostring(MinMS/1000000)
MinBox.TextColor3 = Color3.fromRGB(0, 0, 0)
MinBox.Font = Enum.Font.Gotham
MinBox.TextSize = 14
MinBox.ClearTextOnFocus = false
MinBox.Parent = MainFrame

MinBox.FocusLost:Connect(function()
    local val = parseInput(MinBox.Text)
    if val then
        MinMS = val
        MinLabel.Text = "Min M/s: " .. formatMoney(val)
        saveConfig({ MinMS = MinMS })
        MinBox.Text = tostring(MinMS/1000000)
    else
        MinBox.Text = tostring(MinMS/1000000)
    end
end)

-- 🔄 BUSCAR SERVERS EN API CON VERIFICACIÓN CONTINUA
local function checkServers()
    -- Verificar que la key siga siendo válida en cada petición usando POST (más seguro)
    local validationData = {
        key = _G.KEY,
        hwid = hwid
    }
    local quickValidation = request({
        Url = KEY_VALIDATION_URL,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode(validationData)
    })
    
    if not quickValidation or quickValidation.StatusCode ~= 200 then
        StarterGui:SetCore("SendNotification", {
            Title = "❌ SESIÓN EXPIRADA";
            Text = "Tu key ya no es válida o ha expirado - Error de conexión";
            Duration = 10;
        })
        AutoJoinEnabled = false
        Toggle.Text = "Auto Join: DESACTIVADO (Key Inválida)"
        return {}
    end
    
    -- Parsear respuesta JSON y verificar validez de la key
    local validationData = HttpService:JSONDecode(quickValidation.Body)
    if not validationData or not validationData.valid then
        local errorMsg = validationData and validationData.message or "Key inválida o dispositivo no autorizado"
        StarterGui:SetCore("SendNotification", {
            Title = "❌ SESIÓN EXPIRADA";
            Text = "Tu key ya no es válida: " .. errorMsg;
            Duration = 15;
        })
        AutoJoinEnabled = false
        Toggle.Text = "Auto Join: DESACTIVADO (Key Inválida)"
        return {}
    end
    
    local res = request({ Url = API_URL, Method = "GET" })
    if not res or res.StatusCode ~= 200 then
        warn("Error al pedir datos de la API")
        return {}
    end
    local data = HttpService:JSONDecode(res.Body)
    if not data or not data.servers then return {} end

    local serversToTry = {}
    for _, server in ipairs(data.servers) do
        local s = server.data
        if s and s.money_per_second and s.money_per_second >= MinMS then
            table.insert(serversToTry, s)
        end
    end

    table.sort(serversToTry, function(a, b)
        return math.abs(a.money_per_second - MinMS) < math.abs(b.money_per_second - MinMS)
    end)

    return serversToTry
end

-- Loop principal
task.spawn(function()
    while true do
        if AutoJoinEnabled then
            local servers = checkServers()
            if servers and #servers > 0 then
                for _, s in ipairs(servers) do
                    local join_script = s.join_script
                    if join_script then
                        local func, err = loadstring(join_script)
                        if func then
                            local success, e = pcall(func)
                            if success then
                                print("[AutoJoin] Teleportado exitosamente a servidor con", s.money_per_second, "M/s")
                                break
                            else
                                warn("[AutoJoin] Fallo al ejecutar join_script:", e)
                            end
                        else
                            warn("Error cargando join_script:", err)
                        end
                    end
                end
            else
                print("[AutoJoin] No hay servidores >= " .. formatMoney(MinMS))
            end
        end
        task.wait(1)
    end
end)
