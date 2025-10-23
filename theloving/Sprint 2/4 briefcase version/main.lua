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

-- Market Fluctuation Variables
-- CONFIGURABLE SUPPLY BATCH TIME
local supplyBatchInterval = 60 -- Time between supply additions/price range updates in seconds (Default 1 minute)
local batchTimer = supplyBatchInterval

-- Player Financial and Inventory Data
local defaultStartingMoney = 500 -- <-- Change value to adjust the starting money (e.g., 500, 1000, etc.)
local currentMoney 
local inventory = {} -- Stores how many units of each item the player owns

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

--- School Item BASE Data (The new dictionary structure)
-- Format: { priceRange = {min, max}, supplyRange = {min, max}, demand = constantValue }
-- These are the static settings you can edit.
local itemBaseData = {
    -- The next price will be randomized between 14 and 26.
    -- The new supply batch will be randomized between 5 and 15.
    -- The demand is always 5.
    ["Pen"] =                 { priceRange = {14, 26}, supplyRange = {5, 15}, demand = 5 }, 
    ["Notebook (A4)"] =       { priceRange = {40, 70}, supplyRange = {3, 10}, demand = 6 },
    ["Textbook (Math)"] =     { priceRange = {250, 400}, supplyRange = {1, 5}, demand = 9 },
    ["Eraser"] =              { priceRange = {3, 8}, supplyRange = {10, 25}, demand = 3 },
    ["Highlighter"] =         { priceRange = {10, 20}, supplyRange = {4, 12}, demand = 7 },
    ["Ruler"] =               { priceRange = {8, 15}, supplyRange = {8, 20}, demand = 4 },
    ["Backpack"] =            { priceRange = {120, 200}, supplyRange = {2, 7}, demand = 8 },
    ["USB Drive (16GB)"] =    { priceRange = {60, 95}, supplyRange = {3, 8}, demand = 7 },
    ["Binder Clips (Pack)"] = { priceRange = {10, 18}, supplyRange = {10, 20}, demand = 3 },
}

--- Market Data (Dynamic state, changes every batch interval)
-- Stores: currentPrice (single value), currentSupply (stacking), and the next projections
local marketData = {}


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

-- Helper function to format seconds into MM:SS
local function formatTime(seconds)
    -- Ensure time doesn't go below zero
    seconds = math.max(0, seconds) 
    local minutes = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", minutes, secs)
end

-- Function to calculate the next price and demand range
local function calculateNextMarketProjections()
    for itemName, data in pairs(marketData) do
        local baseData = itemBaseData[itemName]
        
        -- 1. Projected Price (Randomly pick a single value from the defined range)
        local pMin = baseData.priceRange[1]
        local pMax = baseData.priceRange[2]
        data.nextPrice = love.math.random(pMin, pMax) 


        -- 2. Demand Projection (Use the constant demand value)
        data.nextDemand = baseData.demand

        -- 3. Supply Batch Range (Store the editable range for the refresh function)
        data.supplyBatchMinNext = baseData.supplyRange[1]
        data.supplyBatchMaxNext = baseData.supplyRange[2]
    end
end

-- Function to execute the market refresh (Promotes projections to current status)
local function refreshMarket()
    print("Market Refresh Executed! Adding new supply batch...")

    for itemName, data in pairs(marketData) do
        -- 1. Update currentPrice from the projected price
        data.currentPrice = data.nextPrice 

        -- 2. Calculate and Add New Supply Batch (Randomly pick a value from the editable range)
        local newSupplyBatch = love.math.random(data.supplyBatchMinNext, data.supplyBatchMaxNext)
        data.currentSupply = data.currentSupply + newSupplyBatch
    end
    
    -- 3. Immediately calculate the *next* projected prices and demands
    calculateNextMarketProjections() 
end

-- Function to calculate the player's total net worth
local function calculateNetWorth()
    local inventoryValue = 0
    for itemName, count in pairs(inventory) do
        -- Ensure market data exists and has a current price before calculating
        if marketData[itemName] and marketData[itemName].currentPrice then
            inventoryValue = inventoryValue + (count * marketData[itemName].currentPrice)
        end
    end
    return currentMoney + inventoryValue
end

-- Function to calculate the maximum required width for each table column (Used by Network window)
local function calculateColumnWidths()
    local padding = 20 -- Padding for text inside column (10px left, 10px right)
    
    -- Headers
    love.graphics.setFont(MenuF)
    local widths = {
        item = MenuF:getWidth("Item") + padding,
        currentPrice = MenuF:getWidth("Current Price ($)") + padding,
        nextPrice = MenuF:getWidth("Projected Price ($)") + padding, -- Projected Price Header
        demand = MenuF:getWidth("Demand (1-10)") + padding,        -- Demand Header
        netSupply = MenuF:getWidth("Current Supply (Units)") + padding,
    }

    -- Check all item data to find the longest strings
    for itemName, data in pairs(marketData) do
        
        -- Column 1: Item Name
        widths.item = math.max(widths.item, MenuF:getWidth(itemName) + padding)
        
        -- Column 2: Current Price
        local priceNowText = tostring(data.currentPrice)
        widths.currentPrice = math.max(widths.currentPrice, MenuF:getWidth(priceNowText) + padding)
        
        -- Column 3: Projected Price
        local priceNextText = tostring(data.nextPrice)
        widths.nextPrice = math.max(widths.nextPrice, MenuF:getWidth(priceNextText) + padding)

        -- Column 4: Demand
        local demandText = tostring(data.nextDemand)
        widths.demand = math.max(widths.demand, MenuF:getWidth(demandText) + padding)

        -- Column 5: Current Supply
        local supplyText = tostring(data.currentSupply)
        widths.netSupply = math.max(widths.netSupply, MenuF:getWidth(supplyText) + padding)
    end
    
    return widths
end

-- NEW: Helper function to get the dynamic width for the Briefcase window
local function calculateBriefcaseWidth()
    local padding = 20 -- Left/Right margin for the whole window
    local financeColW = 150 -- Fixed width for finance columns
    local financeW = financeColW * 2 + 10 -- Finance table width (2 cols + 10 margin)

    -- --- Inventory Width Calculation ---
    
    local inventoryPadding = 10 -- Inner padding for inventory columns
    local inventoryHasItems = false
    
    -- 1. Calculate max width for the Item Name column
    local inventoryItemColW = MenuF:getWidth("Item") + inventoryPadding -- Start with header width
    for itemName, count in pairs(inventory) do
        if count > 0 then
            inventoryHasItems = true
            inventoryItemColW = math.max(inventoryItemColW, MenuF:getWidth(itemName) + inventoryPadding)
        end
    end
    
    -- 2. Check the "No items" sentence length if the inventory is empty
    local noItemsText = "No items in inventory"
    local noItemsTextW = MenuF:getWidth(noItemsText)
    
    -- The combined width required to center the "No items in inventory" text
    local requiredWForNoItems = noItemsTextW + inventoryPadding * 2 
    
    local quantityColW = MenuF:getWidth("Quantity") + inventoryPadding -- Width for Quantity column

    -- Calculate the Inventory table width (W)
    local inventoryW
    if inventoryHasItems then
        -- Inventory table width = Item Name Column Width + Quantity Column Width + margin (10px)
        inventoryW = inventoryItemColW + quantityColW + 10 
    else
        -- If no items, the table must be wide enough to center the message
        -- The total width must be at least the 'No items' width. We must ensure that 
        -- the current column widths (Item and Quantity) together don't exceed what's needed for the 'No items' text.
        
        local defaultTableW = inventoryItemColW + quantityColW + 10
        inventoryW = math.max(defaultTableW, requiredWForNoItems)
    end


    -- The window width is determined by the widest component + padding
    local contentWidth = math.max(financeW, inventoryW)
    return contentWidth + padding
end


-- Helper function to get the correct dimensions for a window
local function getWindowDimensions(name)
    local w = WindowW
    local h = WindowH
    
    if name == "inbox" then
        local widths = calculateColumnWidths()
        local totalContentWidth = widths.item + widths.currentPrice + widths.nextPrice + widths.demand + widths.netSupply
        w = totalContentWidth + 20 -- Add 20 pixels for left/right window margin (10 on each side)
        h = 450
    elseif name == "briefcase" then 
        -- Briefcase width is now calculated dynamically based on content
        w = calculateBriefcaseWidth()
        h = 400
    end
    return w, h
end


-- Function to draw the Excel-like content for the Network window
local function drawNetworkWindowContent(win)
    local x, y = win.x, win.y
    local contentY = y + TitleBarH + 10 -- Start below the title bar, slightly padded

    love.graphics.setFont(MenuF) -- Use a standard font for content
    local itemHeight = MenuF:getHeight() + 4
    local startX = x + 10 -- Left margin for the content area
    
    -- Dynamically calculate the column widths
    local widths = calculateColumnWidths()
    local col1W = widths.item
    local col2W = widths.currentPrice
    local col3W = widths.nextPrice
    local col4W = widths.demand
    local col5W = widths.netSupply
    local totalWidth = col1W + col2W + col3W + col4W + col5W

    -- Draw Table Header (Old Excel look: Gray background)
    love.graphics.setColor(195/255, 195/255, 195/255) -- Header background
    love.graphics.rectangle("fill", startX, contentY, totalWidth, itemHeight)
    
    love.graphics.setColor(0, 0, 0) -- Text color
    
    local headerY = contentY + 2
    local currentX = startX
    
    -- Column 1: Item
    love.graphics.print("Item", currentX + 5, headerY)
    currentX = currentX + col1W
    
    -- Column 2: Current Price
    love.graphics.print("Current Price ($)", currentX + 5, headerY)
    currentX = currentX + col2W
    
    -- Column 3: Projected Price
    love.graphics.print("Projected Price ($)", currentX + 5, headerY)
    currentX = currentX + col3W
    
    -- Column 4: Demand
    love.graphics.print("Demand (1-10)", currentX + 5, headerY)
    currentX = currentX + col4W
    
    -- Column 5: Current Supply
    love.graphics.print("Current Supply (Units)", currentX + 5, headerY)
    
    love.graphics.setColor(0, 0, 0) -- Border color
    love.graphics.rectangle("line", startX, contentY, totalWidth, itemHeight)

    -- Draw vertical separator lines for header
    currentX = startX
    love.graphics.line(currentX + col1W, contentY, currentX + col1W, contentY + itemHeight)
    currentX = currentX + col1W
    love.graphics.line(currentX + col2W, contentY, currentX + col2W, contentY + itemHeight)
    currentX = currentX + col2W
    love.graphics.line(currentX + col3W, contentY, currentX + col3W, contentY + itemHeight)
    currentX = currentX + col2W
    love.graphics.line(currentX + col4W, contentY, currentX + col4W, contentY + itemHeight)

    contentY = contentY + itemHeight
    
    -- Draw Data Rows
    local rowCounter = 0
    -- *** START OF DRAWING LOOP ***
    for itemName, data in pairs(marketData) do
        -- Retrieve the dynamic values from the marketData dictionary
        local currentPrice = data.currentPrice
        local nextPrice = data.nextPrice
        local nextDemand = data.nextDemand -- The Demand value is constant based on base data
        local currentSupply = data.currentSupply 

        -- Alternate row color for spreadsheet feel
        if rowCounter % 2 == 0 then
            love.graphics.setColor(240/255, 240/255, 240/255) -- Light gray background
        else
            love.graphics.setColor(255/255, 255/255, 255/255) -- White background
        end
        
        -- Draw row background
        love.graphics.rectangle("fill", startX, contentY, totalWidth, itemHeight)
        
        
        currentX = startX
        
        -- Column 1: Item (Black text)
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(itemName, currentX + 5, contentY + 2)
        currentX = currentX + col1W
        
        -- Column 2: Current Price (Black text)
        love.graphics.setColor(0, 0, 0) 
        -- *** CURRENT PRICE IS DRAWN HERE ***
        love.graphics.print(tostring(currentPrice), currentX + 5, contentY + 2)
        currentX = currentX + col2W
        
        -- Column 3: Projected Price (Colored based on change)
        if nextPrice > currentPrice then
            love.graphics.setColor(0/255, 180/255, 0/255) -- Green (Price UP)
        elseif nextPrice < currentPrice then
            love.graphics.setColor(180/255, 0/255, 0/255) -- Red (Price DOWN)
        else
            love.graphics.setColor(0, 0, 0) -- Black (No Change)
        end
        -- *** PROJECTED PRICE IS DRAWN HERE ***
        love.graphics.print(tostring(nextPrice), currentX + 5, contentY + 2)
        currentX = currentX + col3W

        -- Column 4: Demand (Black text, now constant per item)
        love.graphics.setColor(0, 0, 0) 
        -- *** DEMAND IS DRAWN HERE ***
        love.graphics.print(tostring(nextDemand), currentX + 5, contentY + 2)
        currentX = currentX + col4W
        
        -- Column 5: Current Supply (Black text)
        love.graphics.setColor(0, 0, 0) 
        -- *** CURRENT SUPPLY IS DRAWN HERE ***
        love.graphics.print(tostring(currentSupply), currentX + 5, contentY + 2)
        
        -- Draw internal column lines
        love.graphics.setColor(180/255, 180/255, 180/255) -- Light border lines
        currentX = startX
        love.graphics.line(currentX + col1W, contentY, currentX + col1W, contentY + itemHeight)
        currentX = currentX + col1W
        love.graphics.line(currentX + col2W, contentY, currentX + col2W, contentY + itemHeight)
        currentX = currentX + col2W
        love.graphics.line(currentX + col3W, contentY, currentX + col3W, contentY + itemHeight)
        currentX = currentX + col3W
        love.graphics.line(currentX + col4W, contentY, currentX + col4W, contentY + itemHeight)
        
        -- Draw row bottom line
        love.graphics.rectangle("line", startX, contentY, totalWidth, itemHeight)
        
        contentY = contentY + itemHeight
        rowCounter = rowCounter + 1
    end
    -- *** END OF DRAWING LOOP ***
end

-- Function to draw the content for the Briefcase window (Inventory and Finances)
local function drawBriefcaseWindowContent(win)
    local x, y = win.x, win.y
    local contentY = y + TitleBarH + 10 -- Start below the title bar, slightly padded
    local startX = x + 10 -- Left margin for the content area
    local itemHeight = MenuF:getHeight() + 4
    local colW = 150 -- Standard column width for finance
    local padding = 5 
    
    -- Recalculate the current window width (used only if we need to center elements outside the tables)
    -- local currentWindowW, _ = getWindowDimensions(win.name) 
    local financeW = colW * 2 + 10 -- Total width for the finance table
    
    love.graphics.setFont(MenuF)

    -- --- 1. Finance Table (Current Money and Net Worth) ---
    local financeTitle = "Financial Summary"
    local financeX = startX
    
    -- Draw Finance Title
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(financeTitle, financeX, contentY)
    contentY = contentY + MenuF:getHeight() + padding

    
    -- Finance Header (Light Gray)
    love.graphics.setColor(195/255, 195/255, 195/255)
    love.graphics.rectangle("fill", financeX, contentY, financeW, itemHeight)
    
    love.graphics.setColor(0, 0, 0) -- Text color
    local headerY = contentY + 2

    -- Draw Finance Headers
    love.graphics.print("Metric", financeX + padding, headerY)
    love.graphics.print("Value ($)", financeX + colW + padding, headerY)
    
    -- Draw Finance Table lines
    love.graphics.rectangle("line", financeX, contentY, financeW, itemHeight)
    love.graphics.line(financeX + colW, contentY, financeX + colW, contentY + itemHeight)
    contentY = contentY + itemHeight
    
    -- Draw Data Row 1: Current Money
    love.graphics.setColor(255/255, 255/255, 255/255) -- White background
    love.graphics.rectangle("fill", financeX, contentY, financeW, itemHeight)
    love.graphics.setColor(0, 0, 0) 
    love.graphics.print("Current Cash", financeX + padding, contentY + 2)
    -- Format money to two decimal places
    love.graphics.print(tostring(string.format("%.2f", currentMoney)), financeX + colW + padding, contentY + 2)
    love.graphics.rectangle("line", financeX, contentY, financeW, itemHeight)
    love.graphics.line(financeX + colW, contentY, financeX + colW, contentY + itemHeight)
    contentY = contentY + itemHeight

    -- Draw Data Row 2: Net Worth
    local netWorth = calculateNetWorth()
    love.graphics.setColor(240/255, 240/255, 240/255) -- Light gray background
    love.graphics.rectangle("fill", financeX, contentY, financeW, itemHeight)
    love.graphics.setColor(0, 0, 0) 
    love.graphics.print("Net Worth", financeX + padding, contentY + 2)
    love.graphics.print(tostring(string.format("%.2f", netWorth)), financeX + colW + padding, contentY + 2)
    love.graphics.rectangle("line", financeX, contentY, financeW, itemHeight)
    love.graphics.line(financeX + colW, contentY, financeX + colW, contentY + itemHeight)
    
    contentY = contentY + itemHeight + 30 -- Spacer

    -- --- 2. Inventory Table ---
    local inventoryTitle = "Inventory"
    
    -- Draw Inventory Title
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(inventoryTitle, startX, contentY)
    contentY = contentY + MenuF:getHeight() + padding

    -- Recalculate dynamic widths for the inventory table content
    local inventoryPadding = 10 -- Inner padding
    local inventoryHasItems = false
    local inventoryItemColW = MenuF:getWidth("Item") + inventoryPadding -- Start with Item header width
    local quantityColW = MenuF:getWidth("Quantity") + inventoryPadding -- Width for Quantity column
    local noItemsText = "No items in inventory"
    local noItemsTextW = MenuF:getWidth(noItemsText)

    -- Find longest item name
    for itemName, count in pairs(inventory) do
        if count > 0 then 
            inventoryHasItems = true
            inventoryItemColW = math.max(inventoryItemColW, MenuF:getWidth(itemName) + inventoryPadding)
        end
    end
    
    local inventoryW -- Total table width
    if inventoryHasItems then
        -- Inventory table width = Item Name Col Width + Quantity Col Width + 10 (margin)
        inventoryW = inventoryItemColW + quantityColW + 10 
    else
        -- If no items, the table width must be large enough to contain the centered 'No items' text.
        -- We take the maximum of the default column widths and the required width for the no items text.
        local defaultTableW = inventoryItemColW + quantityColW + 10
        local requiredWForNoItems = noItemsTextW + inventoryPadding * 2 -- Text width + 10 left + 10 right
        inventoryW = math.max(defaultTableW, requiredWForNoItems)
        
        -- Since the window's width is already calculated using this final inventoryW value in calculateBriefcaseWidth, 
        -- we are sure the window is wide enough.
        -- We must now ensure the Item Col Width (inventoryItemColW) is correctly calculated to hold the 'No items' text
        -- when no items are present, essentially making the Quantity column disappear by combining the two.
        if inventoryW > defaultTableW then
            -- If the 'No items' text is longer, we force the Item column to take up almost the entire width 
            -- and the quantity column shrinks to minimum (or 0 conceptually).
            inventoryItemColW = inventoryW - 10 - quantityColW
        end
    end

    -- Inventory Header (Light Gray)
    love.graphics.setColor(195/255, 195/255, 195/255)
    love.graphics.rectangle("fill", startX, contentY, inventoryW, itemHeight)
    
    love.graphics.setColor(0, 0, 0) -- Text color
    headerY = contentY + 2

    -- Draw Inventory Headers
    love.graphics.print("Item", startX + padding, headerY)
    love.graphics.print("Quantity", startX + inventoryItemColW + padding, headerY)
    
    -- Draw Inventory Table lines
    love.graphics.rectangle("line", startX, contentY, inventoryW, itemHeight)
    
    -- Draw the vertical separator line ONLY if the inventory is NOT empty.
    if inventoryHasItems then
        love.graphics.line(startX + inventoryItemColW, contentY, startX + inventoryItemColW, contentY + itemHeight)
    end
    contentY = contentY + itemHeight
    
    -- Draw Data Rows
    local rowCounter = 0
    local totalItemsInInventory = 0
    for _, count in pairs(inventory) do
        if count > 0 then totalItemsInInventory = totalItemsInInventory + 1 end
    end

    if totalItemsInInventory > 0 then
        for itemName, count in pairs(inventory) do
            if count > 0 then
                -- Alternate row color
                if rowCounter % 2 == 0 then
                    love.graphics.setColor(255/255, 255/255, 255/255) -- White background
                else
                    love.graphics.setColor(240/255, 240/255, 240/255) -- Light gray background
                end
                
                -- Draw row background
                love.graphics.rectangle("fill", startX, contentY, inventoryW, itemHeight)
                
                love.graphics.setColor(0, 0, 0) -- Text color
                
                -- Item Name
                love.graphics.print(itemName, startX + padding, contentY + 2)
                
                -- Quantity
                love.graphics.print(tostring(count), startX + inventoryItemColW + padding, contentY + 2)
                
                -- Draw lines
                love.graphics.rectangle("line", startX, contentY, inventoryW, itemHeight)
                love.graphics.line(startX + inventoryItemColW, contentY, startX + inventoryItemColW, contentY + itemHeight)
                
                contentY = contentY + itemHeight
                rowCounter = rowCounter + 1
            end
        end
    else
        -- Draw 'No items' row - When inventory is empty
        love.graphics.setColor(255/255, 255/255, 255/255) -- White background
        love.graphics.rectangle("fill", startX, contentY, inventoryW, itemHeight)
        
        love.graphics.setColor(0, 0, 0)
        
        -- Print the text centered within the inventoryW width
        love.graphics.print(noItemsText, 
            startX + inventoryW / 2, 
            contentY + 2, 
            0, 1, 1, 
            noItemsTextW / 2, -- X-Origin: Use half the text width to center
            0 -- Y-Origin
        )
        
        love.graphics.rectangle("line", startX, contentY, inventoryW, itemHeight)
        -- Vertical separator line is intentionally omitted for this "merged" row
    end
end


function love.load()

    love.graphics.setBackgroundColor(0,130/250,130/250)
    wln = love.graphics.getWidth()
    wht = love.graphics.getHeight()
    
    -- Initialize marketData based on itemBaseData
    for itemName, data in pairs(itemBaseData) do
        -- Initialize market data with sensible defaults
        marketData[itemName] = {
            currentPrice = data.priceRange[1], -- Initial price is set to the minimum of its range
            nextPrice = 0,                     -- Projected next price
            nextDemand = data.demand,          -- Constant demand value
            currentSupply = 0,                 -- Initial supply is 0
            
            -- Store supply batch range for the refresh function
            supplyBatchMinNext = data.supplyRange[1], 
            supplyBatchMaxNext = data.supplyRange[2],
        }
        
        -- Player Inventory Initialization
        inventory[itemName] = 0 -- Start with 0 of every item
    end
    
    -- nitialize 1 Pen in the inventory 
    inventory["Pen"] = 1
    
    -- Initialize Player Money
    currentMoney = defaultStartingMoney
    
    -- Calculate the first set of projected ranges immediately
    calculateNextMarketProjections() 

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

    -- Font and icon positioning setup (unchanged)
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
end

function love.update(dt)
    local mouseX = love.mouse.getX()
    local mouseY = love.mouse.getY()
    
    -- Game Timer Update
    if gameState == "desktop" and timeRemaining > 0 then
        timeRemaining = timeRemaining - dt
        if timeRemaining < 0 then
            timeRemaining = 0
            -- Implement Game Over/End Screen logic here
        end
        
        -- Market/Batch Timer Update (runs every supplyBatchInterval seconds)
        batchTimer = batchTimer - dt
        if batchTimer <= 0 then
            refreshMarket() -- Call the new refresh function
            batchTimer = supplyBatchInterval
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
        
        -- State check for timer selection
        if gameState == "selection" then
            for _, btn in ipairs(selectionButtons) do
                if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
                    -- Button clicked! Start timer and switch state
                    timeRemaining = btn.time * 60 -- Convert minutes to seconds
                    gameState = "desktop"
                    -- Trigger initial market update so prices and supply are ready
                    refreshMarket() 
                    return
                end
            end
            return 
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
                local winW, winH = getWindowDimensions(clickedIcon)
                table.insert(openWindows, {
                    name = clickedIcon,
                    x = wln / 2 - winW / 2 + (staggerCount * 20), -- Center it roughly, then stagger
                    y = wht / 2 - winH / 2 + (staggerCount * 20),
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
            cY1 = CloseButtonY
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
    
    -- 6. Draw Content (if the window is the Network or Briefcase app)
    if win.name == "inbox" then
        drawNetworkWindowContent(win)
    elseif win.name == "briefcase" then
        drawBriefcaseWindowContent(win)
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
        
        -- --- Draw Taskbar 
        love.graphics.setColor(195/255, 195/255, 195/255)
        love.graphics.rectangle("fill", TaskBarStartx, TaskBarStarty, TaskBarEndw, TaskBarEndh)
        
        -- Draw the horizontal line separating the desktop from the taskbar
        love.graphics.setColor(1, 1, 1)
        love.graphics.line(0, TaskBarStarty + 3, TaskBarEndw, TaskBarStarty + 3)
        

        
        -- 1. Fill the button with taskbar color
        love.graphics.setColor(195/255, 195/255, 195/255)
        love.graphics.rectangle("fill", StartButx, StartButy, StartButw, StartButh)

        -- 2. Draw 3D bevel (White/Light for Top/Left, Black/Dark for Bottom/Right)
        
        -- Highlight (Top and Left - White)
        love.graphics.setColor(1, 1, 1)
        love.graphics.line(StartButx, StartButy, StartButx + StartButw - 1, StartButy) -- Top
        love.graphics.line(StartButx, StartButy, StartButx, StartButy + StartButh - 1) -- Left

        -- Shadow (Bottom and Right - Black)
        love.graphics.setColor(0, 0, 0)
        love.graphics.line(StartButx, StartButy + StartButh, StartButx + StartButw, StartButy + StartButh) -- Bottom
        love.graphics.line(StartButx + StartButw, StartButy, StartButx + StartButw, StartButy + StartButh) -- Right
        
        -- 3. Draw the menu text
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(MenuF)
        love.graphics.print(Mtext, StartButx + (StartButw / 2), StartButy + (StartButh / 2), 0, 1, 1, MTWidth / 2, MTHeight / 2)
        
        -- Draw the Timer in the bottom left
        if timeRemaining > 0 then
            love.graphics.setColor(0, 0, 0) -- Black text
            love.graphics.setFont(MenuF)
            
            local timerText = "Time Left: " .. formatTime(timeRemaining)
            -- Display market update time remaining
            local marketTimerText = "Next Supply Batch: " .. formatTime(batchTimer)
            
            -- Positioned slightly above the taskbar, to the right of the MENU button
            local timerX = StartButx + StartButw + 15
            local timerY = TaskBarStarty + TaskBarEndh/2 - MenuF:getHeight()/2 
            
            -- Draw Game Timer
            love.graphics.print(timerText, timerX, timerY)
            
            -- Draw Market Timer next to it
            love.graphics.print(marketTimerText, timerX + 150, timerY)
        end
        
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
end
