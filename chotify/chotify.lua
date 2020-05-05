Chotify = LCS.class {
    spawn = {
        direction = "up",
        rightRatio = 0.5,
        bottomRatio = 0.0,
        leftRatio = nil,
        topRatio = 0.0,

        widthRatio = 0.2,
        heightRatio = 0.1,
    }
}

local vsx, vsy

function Chotify:init()
    self.enabled = true
    self.NOTIFICATION_LIMIT = 5
    Spring.Log("Chotify", LOG.NOTICE, "Enabled: " .. tostring(self.enabled))

    self.notifications = {}
    self.totalNotifications = 0
    self._idCounter = 0

    vsx, vsy = Spring.GetViewGeometry()
end

-- this receives the widget:Update callins
function Chotify:_Update()
end

function Chotify:CloseNotification(id)
    local notification = self.notifications[id]
    if notification == nil then
        return
    end
    local window = notification.window
	if not window then
		return
	end
    window:Dispose()
    --[[
    ChiliFX:AddFadeEffect({
        obj = window,
        time = 0.2,
        endValue = 0,
        startValue = 1,
        after = function()
            window:Dispose()
        end,
    })
    ]]
    self.notifications[id] = nil
    self.totalNotifications = self.totalNotifications - 1
    local sorted = self:_SortByStartTimeDesc()
    self:_Realign(sorted)
end

function Chotify:Post(obj)
    if not self.enabled then
        return
    end

    if type(obj) == "string" then
        obj = { body = obj }
    end

    local title = obj.title or ""
    local body = obj.body or ""
    local icon = obj.icon or ""
    local time = obj.time or 5

    if obj.sound then
        Spring.PlaySoundFile(obj.sound, obj.soundVolume or 1)
    end

    local id = self._idCounter
    self._idCounter = self._idCounter + 1

    local direction = Chotify.spawn.direction
    if direction == "up" then
        if Chotify.spawn.bottomRatio == nil then
            Spring.Log("Chotify", LOG.ERROR,  'Missing spawn.bottomRatio when direction=="top"')
        end
    elseif direction == "down" then
        if Chotify.spawn.topRatio == nil then
            Spring.Log("Chotify", LOG.ERROR,  'Missing spawn.topRatio when direction=="bottom"')
        end
    else
        Spring.Log("Chotify", LOG.ERROR, "Invalid direction: " .. tostring(direction) .. '. Should be either "top" nor "bottom"')
    end

    local sp = Chili.ScrollPanel:New {
        x = 5,
        right = 5,
        y = 10,
        bottom = 0,
        autosize = true,
        width = "100%",
        height = "100%",
        resizeItems = false
    }
    local window = Chili.Window:New {
        width = Chotify.spawn.widthRatio * vsx,
        height = Chotify.spawn.heightRatio * vsy,
        x = Chotify.spawn.leftRatio and Chotify.spawn.leftRatio * vsx,
        y = direction == "down" and Chotify.spawn.topRatio * vsy,
        right = Chotify.spawn.rightRatio and Chotify.spawn.rightRatio * vsx,
        bottom = direction == "up" and Chotify.spawn.bottomRatio * vsy,
        caption = title,
        parent = Chili.Screen0,
        draggable = false,
        resizable = false,
        children = {
            sp
        }
    }
    if type(body) == "string" then
        Chili.TextBox:New {
            x = 0,
            y = 5, -- Slight padding because text looks weird otherwise
            width = "100%",
            height = "100%",
            text = body,
            parent = sp,
        }
    else
        sp:AddChild(body)
    end
    --[[
    ChiliFX:AddFadeEffect({
        obj = window,
        time = 0.2,
        endValue = 1,
        startValue = 0,
    })
    ]]
    local startTime = os.clock()
    local notification = {
        window = window,
        startTime = startTime,
        endTime = startTime + time,
        id = id,
    }

    self.notifications[id] = notification
    self.totalNotifications = self.totalNotifications + 1
    -- pop oldest
    local sorted = self:_SortByStartTimeDesc()
    if self.totalNotifications > self.NOTIFICATION_LIMIT then
        self:CloseNotification(sorted[#sorted].id)
    end
    self:_Realign(sorted)
    WG.Delay(function() self:CloseNotification(id) end, time)
    return id
end

-- this modifies the notification
function Chotify:Update(id, obj)
    local title = obj.title
    local body = obj.body
    local notification = self.notifications[id]
    if notification == nil then
        return
    end
    local window = notification.window
    if title ~= nil then
        window:SetCaption(title)
    end
    if body ~= nil then
        if type(body) == "string" then
            window.children[1]:SetCaption(body)
        else
            window.children = body
        end
    end
end

function Chotify:_SortByStartTimeDesc()
    local sorted = {}
    for _, v in pairs(self.notifications) do
        table.insert(sorted, v)
    end
    table.sort(sorted, function(a, b) return a.startTime > b.startTime end)
    return sorted
end

function Chotify:_Realign(sorted)
    local direction = Chotify.spawn.direction
    local windowHeight = Chotify.spawn.heightRatio * vsy
    for i, notification in pairs(sorted) do
        if direction == "up" then
            notification.window:SetPos(nil, vsy * (1 - Chotify.spawn.bottomRatio) - i * windowHeight)
        elseif direction == "down" then
            notification.window:SetPos(nil, Chotify.spawn.topRatio + (i - 1) * windowHeight)
        end
    end
end

function Chotify:ViewResize(vsx_, vsy_)
    vsx = vsx_
    vsy = vsy_
end

function Chotify:Hide(id)
end

function Chotify:Show(id)
end

function Chotify:IsEnabled()
    return self.enabled
end

function Chotify:Enable()
    self.enabled = true
end

function Chotify:Disable()
    self.enabled = false
end

Chotify = Chotify()
