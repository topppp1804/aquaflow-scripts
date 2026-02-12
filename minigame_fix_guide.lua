--[[
    === MINIGAME FIX GUIDE ===
    แก้ 3 จุดในสคริปต์หลัก:

    ============================================================
    จุดที่ 1: แก้ Hook mt.__namecall
    ============================================================
    หาบรรทัด:
        mt.__namecall = newcclosure(function(self, ...)
    
    แทนที่ทั้ง function จนถึง setreadonly(mt, true) ด้วย:
]]

-- === PASTE นี้แทน mt.__namecall ทั้งก้อน ===
local mt = getrawmetatable(game); setreadonly(mt, false); local old = mt.__namecall
mt.__namecall = newcclosure(function(self, ...)
    return old(self, ...)
end); setreadonly(mt, true)
-- === จบจุดที่ 1 ===

--[[
    ============================================================
    จุดที่ 2: ลบ SECTION: MINIGAME AUTO-SKIP SYSTEM ทั้งหมด
    ============================================================
    ลบตั้งแต่:
        -- [[ SECTION: MINIGAME AUTO-SKIP SYSTEM ]]
    จนถึงจบไฟล์ (ลบทั้งหมดเลย)

    ============================================================
    จุดที่ 3: เพิ่ม Physics Hack แทน (ใส่ตรงที่ลบออก)
    ============================================================
    Paste โค้ดนี้ตรงท้ายไฟล์:
]]

-- [[ SECTION: MINIGAME AUTO-PLAY (Physics Hack) ]]
-- ใช้ MinigameController แก้ physics ฝั่ง client ให้เล่นเองอัตโนมัติ
-- ได้ปลา + bonus item ทุกรอบ ไม่ต้องทำอะไร (~5 วินาที)

local MC = require(game:GetService("ReplicatedStorage").common.source.controllers.MinigameController)

RunService.RenderStepped:Connect(function()
    if not Config.AutoMinigame then return end
    local ok, gi = pcall(function() return debug.getupvalue(MC.IsMinigameActive, 1) end)
    if ok and gi and type(gi) == "table" and gi.running then
        -- ปิด gravity ให้ progress ขึ้นอย่างเดียว
        gi.progressGravity = 0
        gi.gravityStrength = 0
        -- ขยาย green zone + simulate กดค้าง
        gi.controlBarScale = 50
        gi.holding = true
        gi.momentum = 1
        gi.targetDirection = 1

        -- หา bonus item ที่ยังไม่เก็บ
        local uc
        if gi.rewards then
            for _, r in ipairs(gi.rewards) do
                if r.progress and r.progress < 1 then uc = r break end
            end
        end
        -- ถ้ามี bonus → ย้ายปลาไปที่ bonus เพื่อเก็บ
        if uc and uc.pos then
            gi._markerCurrent = uc.pos
            gi._markerTarget = uc.pos
        end
        -- zone ตามปลาเสมอ
        if gi._markerCurrent then gi.zonePos = gi._markerCurrent end
    end
end)
print("[AquaFlow] Auto-Play minigame system loaded!")
-- === จบจุดที่ 3 ===
