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

---

---

-- Utility function to get the title of a window
local function getWindowTitle(key)
    if key == "mycomp" then
        return "Buy"
    elseif key == "network" then
        return "Sell"
    elseif key == "inbox" then
        return "Network"
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

---

---

function love.load()

    love.graphics.setBackgroundColor(0,130/250,130/250)
    wln = love.graphics.getWidth()
    wht = love.graphics.getHeight()

    
    mycomp = love.graphics.newImage("w2k-computer-6.png") 
    mycomph = mycomp:getHeight()
    mycompw = mycomp:getWidth()

    networking = love.graphics.newImage("w2k_network_computer-5.png")
    networkingh = networking:getHeight()
    networkingw = networking:getWidth()

    inbox = love.graphics.newImage("w98_mailbox_world-3.png")
    inboxh = inbox:getHeight()
    inboxw = inbox:getWidth()

    briefcase = love.graphics.newImage("w98_briefcase-5.png")
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

    -- Dragging logic
    if isDragging and draggedWindowIndex then
        local win = openWindows[draggedWindowIndex]
        if win then
            -- Update the window's position based on mouse movement and initial offset
            win.x = mouseX - dragOffsetX
            win.y = mouseY - dragOffsetY
        end
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then -- Left mouse button
        
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
            
            -- Calculate Close Button area
            local CloseButtonX = win.x + WindowW - CloseButtonW - 5
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
            local titleX2 = win.x + WindowW
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
    
    local title = getWindowTitle(win.name)
    local CloseButtonX = win.x + WindowW - CloseButtonW - 5
    local CloseButtonY = win.y + 5
    
    -- 1. Draw the main window body (Light Gray)
    love.graphics.setColor(220/255, 220/255, 220/255)
    love.graphics.rectangle("fill", win.x, win.y, WindowW, WindowH)

    -- 2. Draw the Title Bar (Blue)
    love.graphics.setColor(0, 0, 180/255)
    love.graphics.rectangle("fill", win.x, win.y, WindowW, TitleBarH)

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
    love.graphics.rectangle("line", win.x, win.y, WindowW, WindowH)

end


function love.draw()
    -- --- Draw Taskbar (No change)
    love.graphics.setColor(195/255, 195/255, 195/255)
    love.graphics.rectangle("fill", TaskBarStartx, TaskBarStarty, TaskBarEndw, TaskBarEndh)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.line(0, TaskBarStarty + 3, TaskBarEndw, TaskBarStarty + 3)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", StartButx, StartButy, StartButw, StartButh)

    love.graphics.setColor(0, 0, 0)
    love.graphics.line(StartButx, StartButy + StartButh, StartButx + StartButw, StartButy + StartButh, StartButx + StartButw, StartButy)
    
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(MenuF)
    love.graphics.print(Mtext, StartButx + (StartButw / 2), StartButy + (StartButh / 2), 0, 1, 1, MTWidth / 2, MTHeight / 2)
<<<<<<< HEAD
=======

 
    love.graphics.setColor(1, 1, 1)  --- Image drawing

    love.graphics.print(Btxt, 40, 60, 0, 1, 1, Btw/2 )
    love.graphics.print(Stxt, 40, 135, 0, 1, 1, Stw/2 )
    love.graphics.print(NeTxt, 40, 210, 0, 1, 1, NeTxtw/2 )
    love.graphics.print(Brtxt, 40, 280, 0, 1, 1, Brtxtw/2 )

    --love.graphics.draw(drawable (Drawable), x (number), y (number), r (number), sx (number), sy (number), ox (number), oy (number), kx (number), ky (number))
    -- 51  
    --love.graphics.draw(mycomp, 51 / 2, mycomph, 0, 1, 1, mycompw / 2, mycomph / 2)
    love.graphics.draw(mycomp, 40, 10, 0, 1 , 1, mycompw/2)


>>>>>>> bb7fa5bfbccd89716941e73eb583e79ff57ae227
    
    -- --- Draw Desktop Icons (No change)
    love.graphics.setFont(BuyF) 
    
    -- Labels
    love.graphics.setColor(0, 0, 0)
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