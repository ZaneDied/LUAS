local wln, wht
local TaskBarStartx, TaskBarStarty, TaskBarEndw, TaskBarEndh
local StartButx, StartButy, StartButw, StartButh

--- Text
local MTHeight, MTWidth, MenuF
local Mtext = "MENU"
local Btxt = "Buy"
local Stxt = "Sell"
local NeTxt = "Network"
local Brtxt = "Briefcase"

--- Image
local mycomp, mycompw, mycomph
local networking, networkingw, networkingh
local inbox, inboxw, inboxh
local briefcase, briefcasew, briefcaseh


local openWindows = {} 
local staggerCount = 0 

-- Game State and Timer variables
local gameState = "selection" -- "selection" or "desktop"
local timeRemaining = 0        -- Time in seconds
local timerFont
local selectionButtons = {}    -- Stores button positions

-- Window properties (Defaults)
local WindowW = 400
local WindowH = 300
local TitleBarH = 25
local CloseButtonW = 20

local mycompX, mycompY
local networkingX, networkingY
local inboxX, inboxY
local briefcaseX, briefcaseY


local isDragging = false
local draggedWindowIndex = nil -- Index (1, 2, 3...)
local dragOffsetX = 0 
local dragOffsetY = 0 

--- School Item Data (Easy to edit dictionary structure)
-- Format: { item_name = { buyingValue, sellingValue, priority_level_1_to_5 } }
local schoolItems = {
    ["Pen"] = { 20, 10, 3 }, -- Buy: 20, Sell: 10, Priority: 3
    ["Notebook (A4)"] = { 50, 25, 5 },
    ["Textbook (Math)"] = { 300, 150, 5 },
    ["Eraser"] = { 5, 2, 1 },
    ["Highlighter"] = { 15, 7, 2 },
    ["Ruler"] = { 10, 5, 3 },
    ["Backpack"] = { 150, 75, 4 },
    ["USB Drive (16GB)"] = { 75, 40, 4 },
    ["Binder Clips (Pack)"] = { 12, 4, 1 },
}


-- Utility function to get the title of a window
local function getWindowTitle(key)
    if key == "mycomp" then
        return "Buy"
    elseif key == "network" then
        return "Sell"
    elseif key == "inbox" then
        return "Network - School Assets"
    elseif key == "briefcase" then
        return "Briefcase"
    end
    return "Untitled"
end

-- Utility function to find the index of an open window by its app name
local function findWindowIndexByName(appName)
    for i, win in ipairs(openWindows) do
        if win.name == appName then
            return i
        end
    end
    return nil
end

-- Utility function to bring a window to the front
local function bringToFront(index)
    local win = openWindows[index]
    if win then
        -- 1. Remove it from its current position
        table.remove(openWindows, index)
        -- 2. Insert it at the end (which is the top-most layer)
        table.insert(openWindows, win)
    end
end

-- Helper function to get the correct dimensions for a window
local function getWindowDimensions(name)
    local w = WindowW
    local h = WindowH
    -- Make the 'Network' window wider and taller to accommodate the spreadsheet
    if name == "inbox" then
        w = 600
        h = 450
    end
    return w, h
end

-- Helper function to format seconds into MM:SS
local function formatTime(seconds)
    -- Ensure time doesn't go below zero
    seconds = math.max(0, seconds) 
    local minutes = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", minutes, secs)
end

-- Function to draw the Excel-like content for the Network window
local function drawNetworkWindowContent(win)
    local x, y = win.x, win.y
    local contentY = y + TitleBarH + 10 -- Start below the title bar, slightly padded

    love.graphics.setFont(MenuF) -- Use a standard font for content
    local itemHeight = MenuF:getHeight() + 4
    local startX = x + 10
    
    -- New Column Widths for 4 columns (Adjusted sizes to fix overflow)
    local col1W = 180 -- Item name width (Reduced from 200)
    local col2W = 110  -- Buy Value width (Increased from 90 to fit '($)')
    local col3W = 110  -- Sell Value width (Increased from 90 to fit '($)')
    local col4W = 100 -- Priority width
    local totalWidth = col1W + col2W + col3W + col4W -- Total: 500

    -- Draw Table Header (Old Excel look: Gray background)
    love.graphics.setColor(195/255, 195/255, 195/255) -- Header background
    love.graphics.rectangle("fill", startX, contentY, totalWidth, itemHeight)
    
    love.graphics.setColor(0, 0, 0) -- Text color
    
    local headerY = contentY + 2
    local currentX = startX
    
    -- Column 1: Item
    love.graphics.print("Item", currentX + 5, headerY)
    currentX = currentX + col1W
    
    -- Column 2: Buy Value
    love.graphics.print("Buy Value ($)", currentX + 5, headerY)
    currentX = currentX + col2W
    
    -- Column 3: Sell Value (NEW)
    love.graphics.print("Sell Value ($)", currentX + 5, headerY)
    currentX = currentX + col3W
    
    -- Column 4: Priority
    love.graphics.print("Priority (1-5)", currentX + 5, headerY)
    
    love.graphics.setColor(0, 0, 0) -- Border color
    love.graphics.rectangle("line", startX, contentY, totalWidth, itemHeight)

    -- Draw vertical separator lines for header
    currentX = startX
    love.graphics.line(currentX + col1W, contentY, currentX + col1W, contentY + itemHeight)
    currentX = currentX + col1W
    love.graphics.line(currentX + col2W, contentY, currentX + col2W, contentY + itemHeight)
    currentX = currentX + col2W
    love.graphics.line(currentX + col3W, contentY, currentX + col3W, contentY + itemHeight)

    contentY = contentY + itemHeight
    
    -- Draw Data Rows
    local rowCounter = 0
    for itemName, data in pairs(schoolItems) do
        -- data is now { buyingValue, sellingValue, priority }
        local buyValue = data[1]
        local sellValue = data[2] 
        local priority = data[3] 

        -- Alternate row color for spreadsheet feel
        if rowCounter % 2 == 0 then
            love.graphics.setColor(240/255, 240/255, 240/255) -- Light gray background
        else
            love.graphics.setColor(255/255, 255/255, 255/255) -- White background
        end
        
        -- Draw row background
        love.graphics.rectangle("fill", startX, contentY, totalWidth, itemHeight)
        
        -- Draw text (Black)
        love.graphics.setColor(0, 0, 0)
        
        currentX = startX
        
        -- Column 1: Item
        love.graphics.print(itemName, currentX + 5, contentY + 2)
        currentX = currentX + col1W
        
        -- Column 2: Buy Value
        love.graphics.print(tostring(buyValue), currentX + 5, contentY + 2)
        currentX = currentX + col2W
        
        -- Column 3: Sell Value
        love.graphics.print(tostring(sellValue), currentX + 5, contentY + 2)
        currentX = currentX + col3W
        
        -- Column 4: Priority
        love.graphics.print(tostring(priority), currentX + 5, contentY + 2)
        
        -- Draw internal column lines
        love.graphics.setColor(180/255, 180/255, 180/255) -- Light border lines
        currentX = startX
        love.graphics.line(currentX + col1W, contentY, currentX + col1W, contentY + itemHeight)
        currentX = currentX + col1W
        love.graphics.line(currentX + col2W, contentY, currentX + col2W, contentY + itemHeight)
        currentX = currentX + col2W
        love.graphics.line(currentX + col3W, contentY, currentX + col3W, contentY + itemHeight)
        
        -- Draw row bottom line
        love.graphics.rectangle("line", startX, contentY, totalWidth, itemHeight)
        
        contentY = contentY + itemHeight
        rowCounter = rowCounter + 1
    end
end


function love.load()

    love.graphics.setBackgroundColor(0,130/250,130/250)
    wln = love.graphics.getWidth()
    wht = love.graphics.getHeight()
    
    -- Timer font
    timerFont = love.graphics.newFont(20)
    
    -- Set up selection button positions (centered)
    local buttonW = 150
    local buttonH = 50
    local buttonSpacing = 30
    local totalHeight = (buttonH * 3) + (buttonSpacing * 2)
    local startY = wht / 2 - totalHeight / 2
    local startX = wln / 2 - buttonW / 2
    
    selectionButtons = {
        { time = 15, text = "15 Minutes", x = startX, y = startY, w = buttonW, h = buttonH },
        { time = 30, text = "30 Minutes", x = startX, y = startY + buttonH + buttonSpacing, w = buttonW, h = buttonH },
        { time = 60, text = "60 Minutes", x = startX, y = startY + (buttonH + buttonSpacing) * 2, w = buttonW, h = buttonH },
    }

    
    mycomp = love.graphics.newImage("buy.png") 
    mycomph = mycomp:getHeight()
    mycompw = mycomp:getWidth()

    networking = love.graphics.newImage("sell.png")
    networkingh = networking:getHeight()
    networkingw = networking:getWidth()

    inbox = love.graphics.newImage("network.png")
    inboxh = inbox:getHeight()
    inboxw = inbox:getWidth()

    briefcase = love.graphics.newImage("briefcase.png")
    briefcaseh = briefcase:getHeight()
    briefcasew = briefcase:getWidth()

    -- [snip] Font and icon positioning setup (unchanged)
    MenuF = love.graphics.newFont(15)
    love.graphics.setFont(MenuF)
    MTWidth = MenuF:getWidth(Mtext)
    MTHeight = MenuF:getHeight(Mtext)
    
    BuyF = love.graphics.newFont(14)
    love.graphics.setFont(BuyF)
    Btw = BuyF:getWidth(Btxt)
    mycompX, mycompY = 40, 10
    
    SellF = love.graphics.newFont(14)
    love.graphics.setFont(SellF)
    Stw = SellF:getWidth(Stxt)
    networkingX, networkingY = 40, 85

    NetF = love.graphics.newFont(14)
    love.graphics.setFont(NetF)
    NeTxtw = NetF:getWidth(NeTxt) 
    inboxX, inboxY = 40, 160

    BriF = love.graphics.newFont(14)
    love.graphics.setFont(BriF)
    Brtxtw = BriF:getWidth(Brtxt)
    briefcaseX, briefcaseY = 40, 230

    TaskBarStartx = 0
    TaskBarStarty = wht - 50
    TaskBarEndw = wln
    TaskBarEndh = 50
    
    StartButx = 10
    StartButy = TaskBarStarty + 7
    StartButw = 70
    StartButh = 40
    
    WindowTitleF = love.graphics.newFont(16)
    -- [snip] End setup
end

function love.update(dt)
    local mouseX = love.mouse.getX()
    local mouseY = love.mouse.getY()
    
    -- Timer Update
    if gameState == "desktop" and timeRemaining > 0 then
        timeRemaining = timeRemaining - dt
        if timeRemaining < 0 then
            timeRemaining = 0
            -- Note: Add a Game Over/End Screen logic here later if needed!
        end
    end

    -- Dragging logic (only run if in desktop mode)
    if gameState == "desktop" then
        if isDragging and draggedWindowIndex then
            local win = openWindows[draggedWindowIndex]
            if win then
                -- Update the window's position based on mouse movement and initial offset
                win.x = mouseX - dragOffsetX
                win.y = mouseY - dragOffsetY
            end
        end
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then -- Left mouse button
        
        -- NEW: State check for timer selection
        if gameState == "selection" then
            for _, btn in ipairs(selectionButtons) do
                if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
                    -- Button clicked! Start timer and switch state
                    timeRemaining = btn.time * 60 -- Convert minutes to seconds
                    gameState = "desktop"
                    return
                end
            end
            return -- Exit if on selection screen but didn't click a button
        end
        
        -- If we are in desktop mode, run the existing logic:
        
        -- 1. Check for icon clicks (Open a new window)
        if not isDragging then 
            
            local clickedIcon = nil
            
            -- Check My Computer (Icon boundary check)
            if x >= mycompX - mycompw/2 and x < mycompX + mycompw/2 and y >= mycompY and y < mycompY + mycomph then
                clickedIcon = "mycomp"
            end
            
            -- Check Networking
            if x >= networkingX - networkingw/2 and x < networkingX + networkingw/2 and y >= networkingY and y < networkingY + networkingh then
                clickedIcon = "network"
            end
            
            -- Check Inbox
            if x >= inboxX - inboxw/2 and x < inboxX + inboxw/2 and y >= inboxY and y < inboxY + inboxh then
                clickedIcon = "inbox"
            end
            
            -- Check Briefcase
            if x >= briefcaseX - briefcasew/2 and x < briefcaseX + briefcasew/2 and y >= briefcaseY and y < briefcaseY + briefcaseh then
                clickedIcon = "briefcase"
            end
            
            -- If an icon was clicked and that window is not already open, open it
            if clickedIcon and not findWindowIndexByName(clickedIcon) then
                
                staggerCount = staggerCount + 1 -- Increment the offset counter

                -- Create a new window object and insert it at the end of the array
                table.insert(openWindows, {
                    name = clickedIcon,
                    x = 150 + (staggerCount * 20),
                    y = 50 + (staggerCount * 20),
                    active = true 
                })
                return -- Exit early after opening a window
            end
        end

        -- 2. Check for Clicks on Existing Windows (Close/Start Dragging/Bring to Front)
        -- Iterate backwards (from end to start) to check the front-most windows first
        for i = #openWindows, 1, -1 do
            local win = openWindows[i]
            
            local currentWindowW, currentWindowH = getWindowDimensions(win.name) -- Get current size
            
            -- Calculate Close Button area
            local CloseButtonX = win.x + currentWindowW - CloseButtonW - 5
            local CloseButtonY = win.y + 5
            local cX1 = CloseButtonX
            local cY1 = CloseButtonY
            local cX2 = CloseButtonX + CloseButtonW
            local cY2 = CloseButtonY + TitleBarH - 5 

            -- Check for Close Button click
            if x >= cX1 and x <= cX2 and y >= cY1 and y <= cY2 then
                table.remove(openWindows, i) -- Close the window using table.remove
                -- Reset dragging state if the window being dragged was closed
                if draggedWindowIndex == i then
                    isDragging = false
                    draggedWindowIndex = nil
                end
                return -- Stop checking, a window was closed
            end
            
            -- Check for Title Bar Dragging area (Only if a window wasn't just closed)
            local titleX1 = win.x
            local titleY1 = win.y
            local titleX2 = win.x + currentWindowW -- Use current width
            local titleY2 = win.y + TitleBarH

            if x >= titleX1 and x <= titleX2 and y >= titleY1 and y <= titleY2 then
                -- This window was clicked (it's the front-most one clicked due to backward iteration)
                
                -- Bring it to the front *before* starting the drag
                bringToFront(i)
                
                
                draggedWindowIndex = #openWindows
                
                isDragging = true
                dragOffsetX = x - win.x -- Calculate offset from window origin
                dragOffsetY = y - win.y
                
                return -- Stop checking other windows
            end
        end
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    if button == 1 then
        isDragging = false
        draggedWindowIndex = nil
    end
end

---

---

-- Helper function to draw a single window
local function drawWindow(win)
    
    local currentWindowW, currentWindowH = getWindowDimensions(win.name)
    
    local title = getWindowTitle(win.name)
    local CloseButtonX = win.x + currentWindowW - CloseButtonW - 5
    local CloseButtonY = win.y + 5
    
    -- 1. Draw the main window body (Light Gray)
    love.graphics.setColor(220/255, 220/255, 220/255)
    love.graphics.rectangle("fill", win.x, win.y, currentWindowW, currentWindowH)

    -- 2. Draw the Title Bar (Blue)
    love.graphics.setColor(0, 0, 180/255)
    love.graphics.rectangle("fill", win.x, win.y, currentWindowW, TitleBarH)

    -- 3. Draw the Title Text (White)
    love.graphics.setFont(WindowTitleF)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(title, win.x + 5, win.y + 5)
    
    -- 4. Draw the Close Button (X)
    -- Button background (Gray)
    love.graphics.setColor(195/255, 195/255, 195/255)
    love.graphics.rectangle("fill", CloseButtonX, CloseButtonY, CloseButtonW, TitleBarH - 5)
    
    -- Button border (Black)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", CloseButtonX, CloseButtonY, CloseButtonW, TitleBarH - 5)

    -- The 'X' text (Black)
    love.graphics.setFont(MenuF)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("X", CloseButtonX + CloseButtonW/2, CloseButtonY + (TitleBarH - 5)/2, 0, 1, 1, love.graphics.getFont():getWidth("X")/2, love.graphics.getFont():getHeight()/2)
    
    -- 5. Draw the Window Border (Black)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", win.x, win.y, currentWindowW, currentWindowH)
    
    -- 6. Draw Content (if the window is the Network app)
    if win.name == "inbox" then
        drawNetworkWindowContent(win)
    end

end


function love.draw()
    
    if gameState == "selection" then
        -- Draw Timer Selection Screen
        love.graphics.setColor(0, 0, 180/255)
        love.graphics.rectangle("fill", 0, 0, wln, wht)
        
        love.graphics.setFont(WindowTitleF)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Select Game Duration", wln/2, wht/2 - 150, 0, 1, 1, love.graphics.getFont():getWidth("Select Game Duration")/2)
        
        love.graphics.setFont(timerFont)
        
        for _, btn in ipairs(selectionButtons) do
            -- Button background (Gray)
            love.graphics.setColor(195/255, 195/255, 195/255)
            love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h)
            
            -- Button border (Black)
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h)
            
            -- Button text (Black, centered)
            love.graphics.setColor(0, 0, 0)
            love.graphics.print(btn.text, 
                btn.x + btn.w/2, 
                btn.y + btn.h/2, 
                0, 1, 1, 
                love.graphics.getFont():getWidth(btn.text)/2, 
                love.graphics.getFont():getHeight()/2
            )
        end
        
    else -- gameState == "desktop"
        
        -- --- Draw Taskbar (No change)
        love.graphics.setColor(195/255, 195/255, 195/255)
        love.graphics.rectangle("fill", TaskBarStartx, TaskBarStarty, TaskBarEndw, TaskBarEndh)
        
        -- Draw the horizontal line separating the desktop from the taskbar
        love.graphics.setColor(1, 1, 1)
        love.graphics.line(0, TaskBarStarty + 3, TaskBarEndw, TaskBarStarty + 3)
        
        -- --- Draw Start Button (MENU)
        -- 1. Draw the white/light border outline
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", StartButx, StartButy, StartButw, StartButh)

        -- 2. Draw the black shadow on the bottom and right edges
        love.graphics.setColor(0, 0, 0)
        -- Draws a line from BL corner to BR corner, then from BR corner to TR corner
        love.graphics.line(
            StartButx, StartButy + StartButh, 
            StartButx + StartButw, StartButy + StartButh, 
            StartButx + StartButw, StartButy
        )
        
        -- 3. Draw the menu text
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(MenuF)
        love.graphics.print(Mtext, StartButx + (StartButw / 2), StartButy + (StartButh / 2), 0, 1, 1, MTWidth / 2, MTHeight / 2)
        
        -- Draw the Timer in the bottom left
        if timeRemaining > 0 then
            love.graphics.setColor(0, 0, 0) -- Black text
            love.graphics.setFont(MenuF)
            
            local timerText = "Time Left: " .. formatTime(timeRemaining)
            -- Positioned slightly above the taskbar, to the right of the MENU button
            local timerX = StartButx + StartButw + 15
            local timerY = TaskBarStarty + TaskBarEndh/2 - MenuF:getHeight()/2 
            
            love.graphics.print(timerText, timerX, timerY)
        end
        
        -- --- Draw Desktop Icons (No change)
        love.graphics.setFont(BuyF) 
        
        -- Labels
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(Btxt, mycompX, mycompY + mycomph + 5, 0, 1, 1, Btw/2 )
        love.graphics.print(Stxt, networkingX, networkingY + networkingh + 5, 0, 1, 1, Stw/2 )
        love.graphics.print(NeTxt, inboxX, inboxY + inboxh + 5, 0, 1, 1, NeTxtw/2 )
        love.graphics.print(Brtxt, briefcaseX, briefcaseY + briefcaseh + 5, 0, 1, 1, Brtxtw/2 )

        -- Icons
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(mycomp, mycompX, mycompY, 0, 1 , 1, mycompw/2)
        love.graphics.draw(networking, networkingX, networkingY, 0, 1, 1, networkingw/2)
        love.graphics.draw(inbox, inboxX, inboxY, 0, 1, 1, inboxw / 2)
        love.graphics.draw(briefcase, briefcaseX, briefcaseY, 0, 1, 1, briefcasew / 2)

        -- --- Draw Multiple Windows

        for i, win in ipairs(openWindows) do
            drawWindow(win)
        end

        love.graphics.setColor(1, 1, 1) -- Reset color
    end
end
