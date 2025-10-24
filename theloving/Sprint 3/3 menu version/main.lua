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
local failureMessage = "" 
local messageDuration = 0

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
local sellTimerInterval = 5 -- Time between open sell updates in seconds (10 seconds)
local sellTimer = sellTimerInterval

local isMenuOpen = false 
local MenuW = 150 
local MenuH = 150 
local MenuX, MenuY 
local menuButtons = {} -- Stores the clickable button regions and actions

-- Market Fluctuation Variables
-- CONFIGURABLE SUPPLY BATCH TIME
local supplyBatchInterval = 60 -- Time between supply additions/price range updates in seconds (Default 1 minute)
local batchTimer = supplyBatchInterval

-- Player Financial and Inventory Data
local defaultStartingMoney = 500 -- <-- Change value to adjust the starting money (e.g., 500, 1000, etc.)
local currentMoney 
local inventory = {} -- Stores how many units of each item the player owns
local networkLog = {} -- Initialize the log of network events for the 'inbox' window.
local isSellAllSwitchOn = false -- Set the switch to OFF by default
local itemSellSwitches = {} -- Table to track the ON/OFF state of the switch for each item.

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
local totalItemsBought = 0
local totalItemsSold = 0
local totalMoneyEarnedFromSales = 0
local initialStartingMoney = 0 -- Set this to defaultStartingMoney in love.load()
local finalStats = {}          -- Stores the final calculated metrics

--- Market Data (Dynamic state, changes every batch interval)
-- Stores: currentPrice (single value), currentSupply (stacking), and the next projections
local marketData = {}

-- Global variables for the new Buy window UI elements
local BuyButtonW = 30 -- INCREASED WIDTH for the +1, -1, etc. buttons
local BuyButtonH = 24 -- INCREASED HEIGHT
local AmountColW = 80 -- Width for the new 'Amount' (Total Cost/Value) column
local CartColW = 80 -- Width for the Cart Change column
local BuyButtonSpacing = 5 -- Space between buttons and columns
local shoppingCart = {}

local function isInside(x, y, rx, ry, rw, rh)
    return x >= rx and x <= rx + rw and y >= ry and y <= ry + rh
end

local function drawMenu()
    if not isMenuOpen then return end
    
    local x, y = MenuX, MenuY
    local w, h = MenuW, MenuH
    local padding = 5
    local buttonH = MenuF:getHeight() * 1.5 
    
    -- Clear previous button positions
    menuButtons = {} 
    
    -- Draw Menu Background
    love.graphics.setColor(220/255, 220/255, 220/255) -- Light Gray
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(0, 0, 0) -- Black border
    love.graphics.rectangle("line", x, y, w, h)
    
    local options = {"End", "Restart", "Info", "Continue"}
    local nextY = y + padding

    for i, text in ipairs(options) do
        local btnX = x + padding
        local btnW = w - 2 * padding
        local btnY = nextY

        -- Draw Button Background
        love.graphics.setColor(180/255, 180/255, 180/255)
        love.graphics.rectangle("fill", btnX, btnY, btnW, buttonH)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", btnX, btnY, btnW, buttonH)
        
        -- Draw Text (Centered)
        love.graphics.setFont(MenuF)
        love.graphics.setColor(0, 0, 0)
        local textW = MenuF:getWidth(text)
        local textX = btnX + (btnW / 2) - (textW / 2)
        local textY = btnY + (buttonH / 2) - (MenuF:getHeight() / 2)
        love.graphics.print(text, textX, textY)
        
        -- Store button data for mousepressed
        table.insert(menuButtons, {x=btnX, y=btnY, w=btnW, h=buttonH, action=text:lower()})
        
        nextY = btnY + buttonH + padding
    end
end

-- Helper function to execute the full cart transaction
local function executeCartTransaction()
    local totalCost = 0
    
    -- 1. Calculate Total Cost
    for itemName, amount in pairs(shoppingCart) do
        local market = marketData[itemName]
        if market and market.currentPrice then
            totalCost = totalCost + (market.currentPrice * amount)
        end
    end

    -- 2. Check for sufficient funds
    if currentMoney >= totalCost then
        
        -- 3. Execute Purchase
        currentMoney = currentMoney - totalCost
        
        local purchasedItemsCount = 0
        
        for itemName, amount in pairs(shoppingCart) do
            
            -- Update Inventory
            inventory[itemName] = (inventory[itemName] or 0) + amount
            
            -- *** THIS IS THE CORRECT LOCATION TO TRACK THE STATS ***
            purchasedItemsCount = purchasedItemsCount + amount
            
            -- Total Items Purchased for End Screen Stats
            totalItemsBought = totalItemsBought + amount
        end
        
        -- 4. Clear the cart and provide feedback
        shoppingCart = {}
        
        local msg = string.format("PURCHASE SUCCESSFUL! Bought %d items for $%.2f", purchasedItemsCount, totalCost)
        failureMessage = msg
        messageDuration = 3
        
    else
        -- 5. Purchase failed
        failureMessage = "PURCHASE FAILED: Not enough money!"
        messageDuration = 3
    end
end

-- Utility function to get the title of a window
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
    elseif key == "info" then
        return "Help & Information" 
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
    if win and index ~= #openWindows then
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

-- Helper function to get the dynamic width for the Briefcase window
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
    
    -- 2. Check the "No items" sentence length length if the inventory is empty
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
        local defaultTableW = inventoryItemColW + quantityColW + 10
        inventoryW = math.max(defaultTableW, requiredWForNoItems)
    end


    -- The window width is determined by the widest component + padding
    local contentWidth = math.max(financeW, inventoryW)
    return contentWidth + padding
end

-- Logic function for sell switch
local function processOpenSell()
    -- Iterate over all items the player currently owns
    for itemName, count in pairs(inventory) do
        -- Check 1: Does the player have this item? (count > 0)
        -- Check 2: Is the per-item switch set to ON? (itemSellSwitches[itemName] == true)
        if count > 0 and (itemSellSwitches[itemName] == true) then
            
            -- Assuming itemBaseData and marketData are available globally/as up-values
            local baseData = itemBaseData[itemName]
            local market = marketData[itemName]
            
            if not baseData or not market or not market.currentPrice then
                goto continue -- Skip this item if market or base data is incomplete
            end
            
            local currentMarketPrice = market.currentPrice
            local demandChance = baseData.demand -- Demand Priority: Value is 1 to 10
            
            local roll = love.math.random(1, 10)
            
            if roll <= demandChance then
                
                -- --- SALE SUCCESSFUL ---
                
                -- Track sale stats
                totalItemsSold = totalItemsSold + 1
                totalMoneyEarnedFromSales = totalMoneyEarnedFromSales + currentMarketPrice
                
                -- Update Inventory (Sell one unit)
                inventory[itemName] = count - 1
                if inventory[itemName] <= 0 then
                    inventory[itemName] = nil
                end
                
                -- Update Money
                currentMoney = currentMoney + currentMarketPrice
                
                -- Update global message variables
                failureMessage = "AUTO-SOLD: 1x " .. itemName .. " for $" .. string.format("%.2f", currentMarketPrice)
                messageDuration = 3
                
                -- Stop and return immediately after the first successful sale
                return 
            end
        end
        
        ::continue::
    end
end

local function calculateFinalStats()
    local inventoryValue = 0
    
    -- Calculate value of remaining inventory
    for itemName, count in pairs(inventory) do
        local market = marketData[itemName]
        if market and market.currentPrice then
            inventoryValue = inventoryValue + (count * market.currentPrice)
        end
    end
    
    local netWorth = currentMoney + inventoryValue
    
    -- Calculate ratio (handle division by zero)
    local buySellRatioText = "N/A"
    if totalItemsBought > 0 and totalItemsSold > 0 then
        local ratio = totalItemsBought / totalItemsSold
        buySellRatioText = string.format("1 Sold : %.2f Bought", ratio)
    elseif totalItemsBought == 0 and totalItemsSold > 0 then
        buySellRatioText = "Only Sales Recorded"
    elseif totalItemsBought > 0 and totalItemsSold == 0 then
        buySellRatioText = "Only Purchases Recorded"
    else
        buySellRatioText = "No Transactions"
    end

    -- Store results in the global finalStats table
    finalStats.netWorth = netWorth
    finalStats.totalSales = totalItemsSold
    finalStats.totalEarnings = totalMoneyEarnedFromSales
    finalStats.buySellRatio = buySellRatioText
    finalStats.inventoryValue = inventoryValue
end

local function drawEndGameScreen(win, w, h)
    local x, y = win.x, win.y
    local contentY = y + TitleBarH + 20
    local startX = x + 20
    local lineHeight = MenuF:getHeight() + 8
    
    love.graphics.setFont(MenuF)
    love.graphics.setColor(0, 0, 0)
    
    local lines = {
        "--- GAME OVER: FINAL REPORT ---",
        "",
        string.format("Initial Capital: $%s", string.format("%.2f", initialStartingMoney)),
        string.format("Final Cash: $%s", string.format("%.2f", currentMoney)),
        string.format("Inventory Value: $%s", string.format("%.2f", finalStats.inventoryValue)),
        string.format("--------------------------------"),
        string.format("TOTAL NET WORTH: $%s", string.format("%.2f", finalStats.netWorth)),
        string.format("--------------------------------"),
        "",
        string.format("Items Purchased: %d", totalItemsBought),
        string.format("Items Sold: %d", finalStats.totalSales),
        string.format("Total Earnings (from sales): $%s", string.format("%.2f", finalStats.totalEarnings)),
        string.format("Buy/Sell Ratio: %s", finalStats.buySellRatio),
        "",
        "--- Buy/Sell Volume Ratio Graph ---"
    }
    
    -- Draw text lines
    for i, line in ipairs(lines) do
        love.graphics.print(line, startX, contentY)
        contentY = contentY + lineHeight
    end

    -- Simulated Graph (Simple bar chart)
    local graphX = startX
    local graphY = contentY + 10
    local graphW = w - 40
    local graphH = 30
    local totalItems = totalItemsBought + finalStats.totalSales

    if totalItems > 0 then
        -- Calculate widths for the stacked bar
        local ratioSold = finalStats.totalSales / totalItems
        local ratioBought = totalItemsBought / totalItems
        local soldW = ratioSold * graphW
        local boughtW = ratioBought * graphW
        
        -- Draw Bought Bar (Blue)
        love.graphics.setColor(0/255, 120/255, 215/255)
        love.graphics.rectangle("fill", graphX, graphY, boughtW, graphH)
        
        -- Draw Sold Bar (Green, starts after the bought bar)
        love.graphics.setColor(0/255, 150/255, 0/255)
        love.graphics.rectangle("fill", graphX + boughtW, graphY, soldW, graphH)
    else
         love.graphics.setColor(180/255, 180/255, 180/255)
         love.graphics.rectangle("fill", graphX, graphY, graphW, graphH)
         love.graphics.setColor(0, 0, 0)
         love.graphics.print("No transactions recorded.", graphX + 5, graphY + 5)
    end
    
    -- Draw graph border and labels
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", graphX, graphY, graphW, graphH)
    
    love.graphics.print(string.format("Bought: %d", totalItemsBought), graphX, graphY + graphH + 5)
    local soldLabel = string.format("Sold: %d", finalStats.totalSales)
    local soldLabelW = MenuF:getWidth(soldLabel)
    love.graphics.print(soldLabel, graphX + graphW - soldLabelW, graphY + graphH + 5)
end

-- Function to draw the content for the Information/Help window
local function drawInfoWindowContent(win, w, h) 
    local x, y = win.x, win.y
    local contentY = y + TitleBarH + 10 -- Start below the title bar
    
    -- Padding and Wrap Limit
    local sidePadding = 10
    local startX = x + sidePadding
    local wrapLimit = w - (sidePadding * 2) -- Available width for text
    
    -- Spacing between text blocks
    local blockSpacing = 10 
    
    love.graphics.setFont(MenuF)
    love.graphics.setColor(0, 0, 0)
    
    -- Define the help text content (compacted for better wrapping)
    local helpText = {
        "--- Welcome to the School Supply Market! ---",
        "The goal is to make as much money as possible before the time runs out. Buy low, sell high!",
        "",
        "--- Window Guide ---",
        "",
        "1. Buy (Computer Icon):",
        "This is the main market where you buy items. Use the +/- buttons to add items to your cart. The 'Cart' column shows how many you are buying. You can only buy items if there is enough supply in the market. Click 'BUY ITEMS' at the bottom to complete the purchase.",
        "",
        "2. Sell (Server Icon):",
        "This window shows your current inventory and its value. This is where you set up auto-selling. Click the 'Switch' to turn it ON or OFF for an item. When ON, the game will try to sell 1 unit of that item every 5 seconds (as per the 'Open Sell' timer). A sale is only successful if it passes a 'demand check'.",
        "",
        "3. Network (Inbox Icon):",
        "This is your market intelligence report. 'Current Price' is what items cost right now. 'Projected Price' is what the price will be after the next supply batch. 'Demand (1-10)' (e.g., 9) means a higher chance to auto-sell. 'Current Supply' is how many units are available to buy in the 'Buy' window.",
        "",
        "4. Briefcase (Briefcase Icon):",
        "Shows your 'Financial Summary' and 'Inventory'. 'Net Worth' = Your Current Cash + Total Value of all items in your inventory.",
        "",
        "--- Timers (on Taskbar) ---",
        "- Time Left: The main game timer. When it hits 0, the game ends.",
        "- Next Supply Batch: When this hits 0, the market updates (Projected prices become current, and new supply is added).",
        "- Open Sell: How often the game checks to auto-sell items (if switched ON).",
    }
    
    -- Draw each line of text
    for _, line in ipairs(helpText) do
        
        if line == "" then
            -- Just add a small space for an empty line
            contentY = contentY + 8 
        else
            -- Use printf for automatic wrapping
            love.graphics.printf(line, startX, contentY, wrapLimit, "left")
            
            -- Calculate how many lines the text wrapped into
            local _, wrappedLines = MenuF:getWrap(line, wrapLimit)
            
            -- Calculate the height of this text block
            -- (Note: getWrap returns a table of lines, so #wrappedLines is the line count)
            local blockHeight = #wrappedLines * MenuF:getHeight()
            
            -- Advance contentY by the height of the block + spacing
            contentY = contentY + blockHeight + blockSpacing
        end
    end
end

-- Update the getWindowDimensions function to use the new content width.
function getWindowDimensions(name)
    local w = WindowW
    local h = WindowH
    
    if name == "inbox" then
        local widths = calculateColumnWidths()
        -- FIX: The total content width is the sum of all calculated column widths.
        local totalContentWidth = widths.item + widths.currentPrice + widths.nextPrice + widths.demand + widths.netSupply
        w = totalContentWidth + 20 -- Add 20 pixels for left/right window margin (10 on each side)
        
        -- Network window (inbox) dimensions calculation
        local netW = 380 
        local netH = 400
        
        -- Check if the content is larger than the defaults
        local itemHeight = MenuF:getHeight() + 4
        local numEntries = #networkLog 
        local requiredContentHeight = (numEntries * itemHeight) + 10 -- Data rows + padding
        
        -- Minimum height must include title bar, padding, and content
        local minH = TitleBarH + 20 + itemHeight
        
        h = math.max(netH, minH, TitleBarH + requiredContentHeight)
        w = math.max(netW, w) -- Ensure it's wide enough for the column data
        
    elseif name == "briefcase" then 
        -- Briefcase width is now calculated dynamically based on content
        w = calculateBriefcaseWidth()
        h = 400
    elseif name == "mycomp" then -- Calculate width for the Buy window
        local padding = 20 -- Left/Right window margin (10 on each side)
        local contentPadding = 20 -- Inner column padding (10 on each side)

        -- Headers
        local itemHeader = "Item"
        local priceHeader = "Current Price ($)"
        local col1W = MenuF:getWidth(itemHeader) + contentPadding
        local col2W = MenuF:getWidth(priceHeader) + contentPadding

        -- Check all item data to find the longest strings
        for itemName, data in pairs(marketData) do
            col1W = math.max(col1W, MenuF:getWidth(itemName) + contentPadding)
            local priceNowText = tostring(data.currentPrice)
            col2W = math.max(col2W, MenuF:getWidth(priceNowText) + contentPadding)
        end
        
        -- Width for the entire button cluster: 
        -- (6 buttons * ButtonW) + (5 spaces * ButtonSpacing)
        local buttonClusterW = (BuyButtonW * 6) + (BuyButtonSpacing * 5)
        
        -- Total content width for the main table and new elements
        local totalContentWidth = col1W + col2W + BuyButtonSpacing + CartColW + BuyButtonSpacing + AmountColW + BuyButtonSpacing + buttonClusterW
        
        w = totalContentWidth + padding
        
        -- Height calculation adjusted to account for the new 'Buy Items' button/message area
        local numItems = 0
        for _ in pairs(itemBaseData) do numItems = numItems + 1 end
        local itemHeight = MenuF:getHeight() + 4
        
        local headerRowH = itemHeight -- Header row
        local dataRowsH = numItems * itemHeight -- Data rows
        -- Extra space for total summary and the 'Buy Items' button
        local footerH = 30 + BuyButtonH + 10 
        
        h = TitleBarH + 10 + headerRowH + dataRowsH + 10 + footerH
        
    elseif name == "network" then -- Sell Window Dimensions
        local padding = 20
        local itemHeight = MenuF:getHeight() + 4
        
        local inventoryHasItems = false
        local itemColW = MenuF:getWidth("Item") + 10
        local quantityColW = MenuF:getWidth("In Stock") + 10
        local priceColW = MenuF:getWidth("Current Price ($)") + 10
        local valueColW = MenuF:getWidth("Total Value ($)") + 10
        local sellColW = 100 -- Fixed width for the Sell button/input

        -- Calculate max column widths
        for itemName, count in pairs(inventory) do
            if count > 0 then 
                inventoryHasItems = true
                itemColW = math.max(itemColW, MenuF:getWidth(itemName) + 10)
                
                local data = marketData[itemName]
                if data and data.currentPrice then
                    local priceText = string.format("%.2f", data.currentPrice)
                    priceColW = math.max(priceColW, MenuF:getWidth(priceText) + 10)
                    
                    local valueText = string.format("%.2f", count * data.currentPrice)
                    valueColW = math.max(valueColW, MenuF:getWidth(valueText) + 10)
                end
            end
        end
        
        local totalContentWidth = itemColW + quantityColW + priceColW + valueColW + sellColW
        
        -- Adjust width if 'No items' message is longer
        local noItemsTextW = MenuF:getWidth("No tradable items in inventory") + 20
        totalContentWidth = math.max(totalContentWidth, noItemsTextW)
        
        w = totalContentWidth + padding
        
        -- Height is based on number of items + header + title bar
        local numVisibleItems = 0
        for _, count in pairs(inventory) do if count > 0 then numVisibleItems = numVisibleItems + 1 end end
        
        -- Height calculation: TitleBar + Padding(10) + Header Row + Data Rows + Padding(10)
        local dataRows = math.max(1, numVisibleItems) -- At least 1 row for "No items" message
        h = TitleBarH + 10 + itemHeight + (dataRows * itemHeight) + 10
        
        -- If items are visible, increase height slightly for better padding/look
        if numVisibleItems > 0 then
             h = h + 5 
        end

    elseif name == "report" then -- END GAME WINDOW
        w = 550
        h = 550 -- Size for the final report window

    elseif name == "info" then
        w = 550
        h = 520 -- Size for the new Info/Help window
            
    end
    return w, h
end


-- Function To draw the content for Buy window
local function drawBuyWindowContent(win, w, h)
    local x, y = win.x, win.y
    local winW, winH = getWindowDimensions(win.name) -- Get current window width
    local contentY = y + TitleBarH + 10 -- Start below the title bar, slightly padded

    love.graphics.setFont(MenuF) -- Use a standard font for content
    local itemHeight = MenuF:getHeight() + 4
    local startX = x + 10 -- Left margin for the content area
    local padding = 20 -- Padding for text inside column (10px left, 10px right)
    
    -- Headers
    local itemHeader = "Item"
    local priceHeader = "Price ($)"
    local cartChangeHeader = "Cart" -- HEADER
    local amountHeader = "Total Cost"      -- Updated Header
    
    -- Dynamically calculate the column widths for Item and Price
    local col1W = MenuF:getWidth(itemHeader) + padding
    local col2W = MenuF:getWidth(priceHeader) + padding

    -- Check all item data to find the longest strings
    for itemName, data in pairs(marketData) do
        col1W = math.max(col1W, MenuF:getWidth(itemName) + padding)
        local priceNowText = tostring(data.currentPrice)
        col2W = math.max(col2W, MenuF:getWidth(priceNowText) + padding)
    end
    
    -- --- Calculate positions for the table and new columns ---
    
    -- X positions for columns
    local currentX = startX
    local priceColX = currentX + col1W
    local cartColX = priceColX + col2W + BuyButtonSpacing
    local amountColX = cartColX + CartColW + BuyButtonSpacing
    local buttonsX = amountColX + AmountColW + BuyButtonSpacing

    -- The width of the filled (colored) part of the table
    local headerFillW = (amountColX + AmountColW) - startX
    
    -- --- Draw Table Header ---
    
    -- 1. Draw the combined background for the table and amount columns (Gray background)
    love.graphics.setColor(195/255, 195/255, 195/255) 
    love.graphics.rectangle("fill", startX, contentY, headerFillW, itemHeight)
    
    love.graphics.setColor(0, 0, 0) -- Text color
    
    local headerY = contentY + 2
    
    -- Column 1: Item
    love.graphics.print(itemHeader, startX + 5, headerY)
    
    -- Column 2: Price
    love.graphics.print(priceHeader, priceColX + 5, headerY)
    
    -- Column 3: Cart Change (Column Header)
    local cartTextW = MenuF:getWidth(cartChangeHeader)
    local cartTextX = cartColX + (CartColW/2) - (cartTextW/2)
    love.graphics.print(cartChangeHeader, cartTextX, headerY)
    
    -- Column 4: Total Cost (Column Header)
    love.graphics.print(amountHeader, amountColX + 5, headerY)
    
    -- Draw outer border for header
    love.graphics.setColor(0, 0, 0) -- Border color
    love.graphics.rectangle("line", startX, contentY, headerFillW, itemHeight)

    -- Draw vertical separator lines
    love.graphics.line(priceColX, contentY, priceColX, contentY + itemHeight)
    love.graphics.line(cartColX - BuyButtonSpacing, contentY, cartColX - BuyButtonSpacing, contentY + itemHeight)
    love.graphics.line(amountColX - BuyButtonSpacing, contentY, amountColX - BuyButtonSpacing, contentY + itemHeight)
    
    contentY = contentY + itemHeight
    
    -- --- Draw Data Rows and Buttons ---
    local rowCounter = 0
    local currentItemIndex = 1 
    local totalTransactionCost = 0 -- Keep track of the entire order cost
    
    -- *** START OF DRAWING LOOP ***
    for itemName, data in pairs(marketData) do
        local currentPrice = data.currentPrice
        local currentSupply = data.currentSupply
        local cartAmount = shoppingCart[itemName] or 0 -- Get the amount in the cart (can be negative for selling)

        -- Alternate row color for spreadsheet feel
        if rowCounter % 2 == 0 then
            love.graphics.setColor(240/255, 240/255, 240/255) -- Light gray background
        else
            love.graphics.setColor(255/255, 255/255, 255/255) -- White background
        end
        
        -- Draw row background for table and amount column
        love.graphics.rectangle("fill", startX, contentY, headerFillW, itemHeight)
        
        -- Column 1: Item (Black text)
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(itemName, startX + 5, contentY + 2)
        
        -- Column 2: Current Price (Black text)
        love.graphics.setColor(0, 0, 0) 
        love.graphics.print(tostring(currentPrice), priceColX + 5, contentY + 2)
        
        -- Draw internal column lines
        love.graphics.setColor(180/255, 180/255, 180/255) -- Light border lines
        love.graphics.line(priceColX, contentY, priceColX, contentY + itemHeight)
        love.graphics.line(cartColX - BuyButtonSpacing, contentY, cartColX - BuyButtonSpacing, contentY + itemHeight)
        love.graphics.line(amountColX - BuyButtonSpacing, contentY, amountColX - BuyButtonSpacing, contentY + itemHeight)

        -- Draw row bottom line for the filled part
        love.graphics.rectangle("line", startX, contentY, headerFillW, itemHeight)
        
        -- --- Column 3: Cart Change (The amount in the cart) ---
        love.graphics.setColor(0, 0, 0) 
        local cartText = tostring(cartAmount)
        
        -- Center the text in the Cart Change column
        local textW = MenuF:getWidth(cartText)
        local textX = cartColX + (CartColW/2) - (textW/2)
        love.graphics.print(cartText, textX, contentY + 2)
        
        -- --- Column 4: Total Cost (Current Cart Change * Current Price) ---
        local itemTotalCost = cartAmount * currentPrice -- Positive for buying, negative for selling
        totalTransactionCost = totalTransactionCost + itemTotalCost 
        
        love.graphics.setColor(0, 0, 0) 
        local amountText = string.format("$%.2f", math.abs(itemTotalCost)) -- Show absolute value for display
        
        -- Center the text in the Total Cost column
        local textW = MenuF:getWidth(amountText)
        local textX = amountColX + (AmountColW/2) - (textW/2)
        love.graphics.print(amountText, textX, contentY + 2)
        
        -- --- Draw Buy/Adjust Buttons ---
        local currentButtonX = buttonsX
        local buttonY = contentY + (itemHeight/2) - (BuyButtonH/2) -- Center buttons vertically
        local buttonIndex = 1
        
        -- Button data: {text, value}
        local cartButtons = {
            {"+1", 1}, {"+5", 5}, {"+10", 10}, {"-10", -10}, {"-5", -5}, {"-1", -1}
        }
        
        for _, btn in ipairs(cartButtons) do
            local btnText = btn[1]
            local btnValue = btn[2]
            local isBuyButton = btnValue > 0
            local isActive = true
            
            -- Check for constraints to disable the button
            if isBuyButton then
                -- Disable Buy button if market supply is 0
                if currentSupply <= 0 then isActive = false end 
            else
                -- Disable Sell button if cart amount is 0 (or less than the magnitude of the sell button)
                -- e.g. Cannot press -5 if cart is only -3
                if cartAmount == 0 or cartAmount < math.abs(btnValue) then isActive = false end 
            end
            
            -- Store button data for click detection
            -- Key format: "cart_itemIndex_buttonIndex"
            local buttonKey = string.format("cart_%d_%d", currentItemIndex, buttonIndex)
            
            -- Add button data to the window's data structure for mousepressed check
            win[buttonKey] = {
                item = itemName,
                change = btnValue, -- Store as 'change' not 'amount'
                x = currentButtonX,
                y = buttonY,
                w = BuyButtonW,
                h = BuyButtonH,
                active = isActive
            }
            
            -- Draw Button Background
            if isActive then
                love.graphics.setColor(195/255, 195/255, 195/255) -- Gray
            else
                love.graphics.setColor(150/255, 150/255, 150/255) -- Darker gray for disabled
            end
            love.graphics.rectangle("fill", currentButtonX, buttonY, BuyButtonW, BuyButtonH)
            
            -- Draw Button Border
            love.graphics.setColor(0, 0, 0) -- Black
            love.graphics.rectangle("line", currentButtonX, buttonY, BuyButtonW, BuyButtonH)
            
            -- Draw Button Text (Black)
            love.graphics.setColor(0, 0, 0)
            local textWidth = MenuF:getWidth(btnText)
            local textX = currentButtonX + (BuyButtonW/2) - (textWidth/2)
            love.graphics.print(btnText, textX, buttonY + 2)
            
            currentButtonX = currentButtonX + BuyButtonW + BuyButtonSpacing
            buttonIndex = buttonIndex + 1
        end
        
        contentY = contentY + itemHeight
        rowCounter = rowCounter + 1
        currentItemIndex = currentItemIndex + 1
    end
    -- *** END OF DRAWING LOOP ***
    
    -- --- Footer: Total Summary and Buy Button ---
    local footerY = contentY + 10

    -- 1. Display Total Cost
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(string.format("Current Cash: $%.2f", currentMoney), startX, footerY)
    
    local totalText = string.format("Net Cart Cost: $%.2f", totalTransactionCost)
    local totalTextW = MenuF:getWidth(totalText)
    love.graphics.print(totalText, win.x + winW - totalTextW - 10, footerY)

    footerY = footerY + MenuF:getHeight() + 5
    
    -- 2. Draw Final Buy Button
    local BuyButtonText = "BUY ITEMS"
    local BuyButtonW_Final = MenuF:getWidth(BuyButtonText) + 20 -- Make it large enough
    
    -- Center the final button at the bottom right
    local FinalButtonX = win.x + w - BuyButtonW_Final - 10
    local FinalButtonY = footerY 
    
    -- Determine if the button should be active
    local isBuyActive = true
    if totalTransactionCost > currentMoney or totalTransactionCost == 0 then
        isBuyActive = false
    end
    
    -- Store final button data for click detection
    win["FINAL_BUY_BUTTON"] = {
        x = FinalButtonX,
        y = FinalButtonY,
        w = BuyButtonW_Final,
        h = BuyButtonH,
        active = isBuyActive
    }
    
    -- Draw Final Button Background
    if isBuyActive then
        love.graphics.setColor(0/255, 150/255, 0/255) -- Green for Active
    else
        love.graphics.setColor(150/255, 150/255, 150/255) -- Gray for Disabled
    end
    love.graphics.rectangle("fill", FinalButtonX, FinalButtonY, BuyButtonW_Final, BuyButtonH)
    
    -- Draw Button Border
    love.graphics.setColor(0, 0, 0) 
    love.graphics.rectangle("line", FinalButtonX, FinalButtonY, BuyButtonW_Final, BuyButtonH)
    
    -- Draw Button Text (White/Black)
    love.graphics.setColor(255, 255, 255) -- White text on green/gray
    local textWidth = MenuF:getWidth(BuyButtonText)
    local textX = FinalButtonX + (BuyButtonW_Final/2) - (textWidth/2)
    love.graphics.print(BuyButtonText, textX, FinalButtonY + 2)

end

-- Function to draw the content for the Sell window (Inventory and Market Price)
local function drawSellWindowContent(win, w, h)
    local x, y = win.x, win.y
    local contentY = y + TitleBarH + 10 -- Start below the title bar, slightly padded
    local startX = x + 10 -- Left margin for the content area
    local itemHeight = MenuF:getHeight() + 4
    local padding = 10 
    
    love.graphics.setFont(MenuF)

    -- --- 1. Calculate dynamic column widths ---
    local inventoryHasItems = false
    local itemColW = MenuF:getWidth("Item") + padding
    local quantityColW = MenuF:getWidth("In Stock") + padding
    local priceColW = MenuF:getWidth("Current Price ($)") + padding
    local valueColW = MenuF:getWidth("Total Value ($)") + padding
    
    -- Fixed width for the SELL button/input
    local sellColW = 80 -- Width for the switch column (was 100 before, setting to 80 for switch size)

    for itemName, count in pairs(inventory) do
        if count > 0 then 
            inventoryHasItems = true
            itemColW = math.max(itemColW, MenuF:getWidth(itemName) + padding)
            
            local data = marketData[itemName]
            if data and data.currentPrice then
                local priceText = string.format("%.2f", data.currentPrice)
                priceColW = math.max(priceColW, MenuF:getWidth(priceText) + padding)
                
                local valueText = string.format("%.2f", count * data.currentPrice)
                valueColW = math.max(valueColW, MenuF:getWidth(valueText) + padding)
            end
        end
    end
    
    local totalWidth = itemColW + quantityColW + priceColW + valueColW + sellColW
    
    -- If no items, ensure it is wide enough for the "No items" message
    local noItemsText = "No tradable items in inventory"
    local noItemsTextW = MenuF:getWidth(noItemsText) + 20
    if not inventoryHasItems then
        -- This logic ensures the 'No items' row covers the same width as the header
        totalWidth = math.max(totalWidth, noItemsTextW + sellColW) -- Ensure width covers the added Switch column width
    end
    
    -- --- 2. Draw Table Header ---
    local headerX = startX
    
    -- Header Background (Light Gray)
    love.graphics.setColor(195/255, 195/255, 195/255)
    love.graphics.rectangle("fill", headerX, contentY, totalWidth, itemHeight)
    
    love.graphics.setColor(0, 0, 0) -- Text color
    local headerY = contentY + 2
    local currentX = headerX

    -- Draw Headers
    love.graphics.print("Item", currentX + 5, headerY) -- Using 5px inner padding
    currentX = currentX + itemColW
    
    love.graphics.print("In Stock", currentX + 5, headerY)
    currentX = currentX + quantityColW
    
    love.graphics.print("Current Price ($)", currentX + 5, headerY)
    currentX = currentX + priceColW
    
    love.graphics.print("Total Value ($)", currentX + 5, headerY)
    currentX = currentX + valueColW
    
    love.graphics.print("Switch", currentX + 5, headerY) -- Header for the new Switch column

    -- Draw Table lines
    love.graphics.setColor(0, 0, 0) -- Border color
    love.graphics.rectangle("line", headerX, contentY, totalWidth, itemHeight)
    
    -- Draw vertical separator lines for header
    currentX = headerX
    love.graphics.line(currentX + itemColW, contentY, currentX + itemColW, contentY + itemHeight)
    currentX = currentX + itemColW
    love.graphics.line(currentX + quantityColW, contentY, currentX + quantityColW, contentY + itemHeight)
    currentX = currentX + quantityColW
    love.graphics.line(currentX + priceColW, contentY, currentX + priceColW, contentY + itemHeight)
    currentX = currentX + priceColW
    love.graphics.line(currentX + valueColW, contentY, currentX + valueColW, contentY + itemHeight)
    currentX = currentX + valueColW
    love.graphics.line(currentX + sellColW, contentY, currentX + sellColW, contentY + itemHeight) -- Final column line

    contentY = contentY + itemHeight
    
    -- --- 3. Draw Data Rows ---
    local rowCounter = 0
    
    -- Clear previous switch data to store only the currently drawn ones
    win.itemSellSwitches = {} 

    if inventoryHasItems then
        for itemName, count in pairs(inventory) do
            if count > 0 then
                local data = marketData[itemName]
                local currentPrice = data and data.currentPrice or 0
                local totalValue = count * currentPrice
                
                -- Alternate row color
                if rowCounter % 2 == 0 then
                    love.graphics.setColor(255/255, 255/255, 255/255) -- White background
                else
                    love.graphics.setColor(240/255, 240/255, 240/255) -- Light gray background
                end
                
                -- Draw row background
                love.graphics.rectangle("fill", startX, contentY, totalWidth, itemHeight)
                
                love.graphics.setColor(0, 0, 0) -- Text color
                currentX = startX
                
                -- Column 1: Item Name
                love.graphics.print(itemName, currentX + 5, contentY + 2)
                currentX = currentX + itemColW
                
                -- Column 2: In Stock (Quantity)
                love.graphics.print(tostring(count), currentX + 5, contentY + 2)
                currentX = currentX + quantityColW
                
                -- Column 3: Current Price
                love.graphics.print(string.format("%.2f", currentPrice), currentX + 5, contentY + 2)
                currentX = currentX + priceColW
                
                -- Column 4: Total Value
                love.graphics.print(string.format("%.2f", totalValue), currentX + 5, contentY + 2)
                currentX = currentX + valueColW
                
                -- Column 5: SWITCH area
                
                -- Get current state, defaulting to OFF if not set
                local isSellActive = itemSellSwitches[itemName] or false
                itemSellSwitches[itemName] = isSellActive -- Ensure it's tracked even if it was nil

                -- --- DRAW USELESS ON/OFF SWITCH ---
                -- Switch dimensions and position
                local SwitchW = 60 -- Slightly smaller switch than the column width
                local SwitchH = itemHeight - 4
                local SwitchY = contentY + 2
                -- Center the switch within the sellColW space
                local SwitchX = currentX + (sellColW/2) - (SwitchW/2) 
                local thumbW = SwitchH - 4 

                -- 1. Draw the track
                local trackColor = isSellActive and {0, 150/255, 0} or {180/255, 180/255, 180/255} 
                love.graphics.setColor(unpack(trackColor)) 
                love.graphics.rectangle("fill", SwitchX, SwitchY, SwitchW, SwitchH)
                love.graphics.setColor(0, 0, 0)
                love.graphics.rectangle("line", SwitchX, SwitchY, SwitchW, SwitchH)
                
                -- 2. Draw the thumb/slider
                local thumbColor = isSellActive and {20/255, 20/255, 20/255} or {150/255, 150/255, 150/255}
                local thumbX = isSellActive and (SwitchX + SwitchW - thumbW - 2) or (SwitchX + 2)
                love.graphics.setColor(unpack(thumbColor))
                love.graphics.rectangle("fill", thumbX, SwitchY + 2, thumbW, thumbW)
                love.graphics.setColor(0, 0, 0)
                love.graphics.rectangle("line", thumbX, SwitchY + 2, thumbW, thumbW)

                -- 3. Draw the label
                local label = isSellActive and "ON" or "OFF"
                love.graphics.setColor(0, 0, 0) 
                local labelW = MenuF:getWidth(label)
                local labelX = isSellActive and (SwitchX + 5) or (SwitchX + SwitchW - labelW - 5)
                love.graphics.print(label, labelX, SwitchY + (SwitchH - MenuF:getHeight()) / 2) 

                -- 4. Store the switch's bounds for click detection
                -- Store the button under a unique key containing the item name
                win.itemSellSwitches["sell_switch_" .. itemName] = {
                    x = SwitchX, 
                    y = SwitchY, 
                    w = SwitchW, 
                    h = SwitchH,
                    item = itemName -- Store the item name for click handling
                }
                
                -- Draw horizontal and vertical row lines
                love.graphics.setColor(180/255, 180/255, 180/255) -- Light border lines
                love.graphics.rectangle("line", startX, contentY, totalWidth, itemHeight)
                currentX = startX
                love.graphics.line(currentX + itemColW, contentY, currentX + itemColW, contentY + itemHeight)
                currentX = currentX + itemColW
                love.graphics.line(currentX + quantityColW, contentY, currentX + quantityColW, contentY + itemHeight)
                currentX = currentX + quantityColW
                love.graphics.line(currentX + priceColW, contentY, currentX + priceColW, contentY + itemHeight)
                currentX = currentX + priceColW
                love.graphics.line(currentX + valueColW, contentY, currentX + valueColW, contentY + itemHeight)
                
                contentY = contentY + itemHeight
                rowCounter = rowCounter + 1
            end
        end
    else 
        -- Draw 'No items' row - When inventory is empty
        love.graphics.setColor(255/255, 255/255, 255/255) -- White background
        love.graphics.rectangle("fill", startX, contentY, totalWidth, itemHeight)
        love.graphics.setColor(0, 0, 0) -- Print the text centered within the totalWidth
        local textToPrint = noItemsText
        local textW = MenuF:getWidth(textToPrint)
        love.graphics.print(textToPrint, startX + totalWidth / 2, contentY + 2, 0, 1, 1, textW / 2, 0)
        love.graphics.rectangle("line", startX, contentY, totalWidth, itemHeight)
        
        contentY = contentY + itemHeight -- Move contentY past the 'no items' row
    end
    
    -- NOTE: Removed the single switch drawing from the previous iteration.
end

-- Function to draw the Excel-like content for the Network window
local function drawNetworkWindowContent(win, w, h)
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

    -- FIX: Correctly draw vertical separator lines for header
    currentX = startX
    currentX = currentX + col1W
    love.graphics.line(currentX, contentY, currentX, contentY + itemHeight)
    currentX = currentX + col2W
    love.graphics.line(currentX, contentY, currentX, contentY + itemHeight)
    currentX = currentX + col3W
    love.graphics.line(currentX, contentY, currentX, contentY + itemHeight)
    currentX = currentX + col4W
    love.graphics.line(currentX, contentY, currentX, contentY + itemHeight)

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
        
        -- FIX: Correctly draw internal column lines
        love.graphics.setColor(180/255, 180/255, 180/255) -- Light border lines
        currentX = startX
        currentX = currentX + col1W
        love.graphics.line(currentX, contentY, currentX, contentY + itemHeight)
        currentX = currentX + col2W
        love.graphics.line(currentX, contentY, currentX, contentY + itemHeight)
        currentX = currentX + col3W
        love.graphics.line(currentX, contentY, currentX, contentY + itemHeight)
        currentX = currentX + col4W
        love.graphics.line(currentX, contentY, currentX, contentY + itemHeight)
        
        -- Draw row bottom line
        love.graphics.rectangle("line", startX, contentY, totalWidth, itemHeight)
        
        contentY = contentY + itemHeight
        rowCounter = rowCounter + 1
    end
    -- *** END OF DRAWING LOOP ***
end

-- Function to draw the content for the Briefcase window (Inventory and Finances)
local function drawBriefcaseWindowContent(win, w, h)
    local x, y = win.x, win.y
    local contentY = y + TitleBarH + 10 -- Start below the title bar, slightly padded
    local startX = x + 10 -- Left margin for the content area
    local itemHeight = MenuF:getHeight() + 4
    local colW = 150 -- Standard column width for finance
    local padding = 5 
    
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
        local defaultTableW = inventoryItemColW + quantityColW + 10
        local requiredWForNoItems = noItemsTextW + inventoryPadding * 2 
        inventoryW = math.max(defaultTableW, requiredWForNoItems)
        
        if inventoryW > defaultTableW then
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
    end
end

-- Function to reset all game variables to their default state
local function resetGame()
    -- Reset game state
    gameState = "selection"
    timeRemaining = 0
    
    -- Clear windows and dragging
    openWindows = {}
    isDragging = false
    draggedWindowIndex = nil
    staggerCount = 0
    
    -- Clear UI state
    isMenuOpen = false
    failureMessage = ""
    messageDuration = 0

    -- Reset timers
    batchTimer = supplyBatchInterval
    sellTimer = sellTimerInterval
    
    -- Reset player data
    currentMoney = defaultStartingMoney
    inventory = {}
    shoppingCart = {}
    marketData = {} -- Clear old market data
    
    -- Re-initialize market and inventory (copied from love.load)
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
    
    -- Calculate the first set of projected ranges immediately
    calculateNextMarketProjections() 
    
    -- Reset stats
    totalItemsBought = 0
    totalItemsSold = 0
    totalMoneyEarnedFromSales = 0
    initialStartingMoney = 0 -- This will be set properly when the *next* game starts
    finalStats = {}
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
    
    -- [THE CRITICAL FIX]: Initializing window constants
    TitleBarH = 25 
    CloseButtonW = 20
    
    -- Call the reset function to set up the initial game state
    resetGame()
end


function love.update(dt)
    -- This block contains all game-time dependent logic (timers and messages)
    if gameState == "desktop" then
        
        -- 1. Game Countdown Timer (Main Timer)
        if timeRemaining > 0 then
            timeRemaining = timeRemaining - dt
            if timeRemaining <= 0 then
                timeRemaining = 0
                
                -- Trigger end game sequence
                calculateFinalStats()
                gameState = "endgame" 
                
                -- Set up the End Game Window (FIXED: Added w and h)
                local winName = "report"
                local winW, winH = getWindowDimensions(winName)
                table.insert(openWindows, {
                    name = winName,
                    x = wln / 2 - winW / 2, 
                    y = wht / 2 - winH / 2, 
                    active = true,
                    w = winW, -- *** ADDED THIS LINE ***
                    h = winH  -- *** ADDED THIS LINE ***
                })
                
                return -- Crucial: Exit update loop after setting endgame state
            end
        end

        -- 2. Market Refresh Timer (Stops when gameState != "desktop")
        batchTimer = batchTimer - dt
        if batchTimer <= 0 then
            refreshMarket()
            batchTimer = supplyBatchInterval -- Reset timer
        end
        
        -- 3. Open Sell Timer (STOPS when gameState != "desktop")
        sellTimer = sellTimer - dt
        if sellTimer <= 0 then
            processOpenSell() 
            sellTimer = sellTimerInterval -- Reset timer
        end

        -- 4. Message Timer
        if messageDuration > 0 then
            messageDuration = messageDuration - dt
            if messageDuration <= 0 then
                failureMessage = "" -- Clear the message
            end
        end
    end

    -- 5. Handle Dragging Logic
    -- This runs regardless of desktop/endgame state, allowing the report window to be moved.
    if isDragging and draggedWindowIndex then
        local mx, my = love.mouse.getPosition()
        local win = openWindows[draggedWindowIndex]
        
        -- Apply movement
        win.x = mx - dragOffsetX
        win.y = my - dragOffsetY
    end
end


function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then -- Left mouse button
        
        -- State check for timer selection
        if gameState == "selection" then
            for _, btn in ipairs(selectionButtons) do
                -- Use isInside helper function
                if isInside(x, y, btn.x, btn.y, btn.w, btn.h) then
                    -- Button clicked! Start timer and switch state
                    timeRemaining = btn.time * 60 -- Convert minutes to seconds
                    gameState = "desktop"
                    
                    -- Trigger initial market update so prices and supply are ready
                    refreshMarket() 
                    
                    -- Set the initial money for the final report
                    initialStartingMoney = currentMoney
                    return
                end
            end
            return 
        end
        
        -- --- MENU LOGIC (Priority Check) ---
        -- This logic runs in both "desktop" and "endgame" states.
        
        -- 1. Check for click on the main MENU button (Toggle menu visibility)
        if isInside(x, y, StartButx, StartButy, StartButw, StartButh) then
            isMenuOpen = not isMenuOpen
            
            -- Calculate Menu position (Drops up from the taskbar, aligned left)
            -- We do this here so it's fresh every time it's opened
            MenuX = StartButx
            MenuY = StartButy - MenuH 
            
            return -- Click handled
        end

        -- 2. Check for clicks inside the open menu
        if isMenuOpen then
            for _, btn in ipairs(menuButtons) do
                if isInside(x, y, btn.x, btn.y, btn.w, btn.h) then
                    
                    -- Check which button was clicked
                    if btn.action == "end" then
                        -- Set timer to 5 seconds
                        timeRemaining = 5
                        print("Menu action: 'End' clicked. Timer set to 5 seconds.")
                        
                    elseif btn.action == "restart" then
                        -- [MODIFICATION] Call the resetGame function
                        resetGame()
                        print("Menu action: 'Restart' clicked. Game is resetting.")
                        
                    elseif btn.action == "info" then
                        -- --- START OF MODIFICATION ---
                        print("Menu action: 'Info' clicked. Opening info window.")
                        -- Check if the 'info' window is already open
                        if not findWindowIndexByName("info") then
                            -- Get its dimensions
                            local winName = "info"
                            local winW, winH = getWindowDimensions(winName)
                            
                            -- Open it (centered)
                            table.insert(openWindows, {
                                name = winName,
                                x = wln / 2 - winW / 2, 
                                y = wht / 2 - winH / 2, 
                                active = true,
                                w = winW,
                                h = winH
                            })
                        end

                        
                    elseif btn.action == "continue" then
                        print("Menu action: 'Continue' clicked (no logic implemented)")
                        
                    end

                    -- Close the menu on any click
                    isMenuOpen = false
                    return -- Click handled
                end
            end
            
            -- If a click occurred outside the menu area, close the menu (good UX)
            if not isInside(x, y, MenuX, MenuY, MenuW, MenuH) then
                 isMenuOpen = false
            end
            
            -- IMPORTANT: If the menu was open, we stop here. 
            -- We don't want to click "through" the menu onto windows or icons.
            return 
        end
        -- --- [END] MENU LOGIC ---


        -- If we are in "desktop" mode (and menu logic didn't catch the click), run the icon logic:
        if gameState == "desktop" then
        
            -- 1. Check for icon clicks (Open a new window)
            if not isDragging then 
                
                local clickedIcon = nil
                
                -- Check My Computer (Icon boundary check)
                if isInside(x, y, mycompX - mycompw/2, mycompY, mycompw, mycomph) then
                    clickedIcon = "mycomp"
                end
                
                -- Check Networking
                if isInside(x, y, networkingX - networkingw/2, networkingY, networkingw, networkingh) then
                    clickedIcon = "network"
                end
                
                -- Check Inbox
                if isInside(x, y, inboxX - inboxw/2, inboxY, inboxw, inboxh) then
                    clickedIcon = "inbox"
                end
                
                -- Check Briefcase
                if isInside(x, y, briefcaseX - briefcasew/2, briefcaseY, briefcasew, briefcaseh) then
                    clickedIcon = "briefcase"
                end
                
                -- If an icon was clicked and that window is not already open, open it
                if clickedIcon and not findWindowIndexByName(clickedIcon) then
                    
                    local safeStagger = staggerCount % 5 
                    local offsetAmount = safeStagger * 20 
                    
                    staggerCount = staggerCount + 1 

                    local winW, winH = getWindowDimensions(clickedIcon)
                    table.insert(openWindows, {
                        name = clickedIcon,
                        x = wln / 2 - winW / 2 + offsetAmount, 
                        y = wht / 2 - winH / 2 + offsetAmount, 
                        active = true 
                    })
                    return -- Exit early after opening a window
                end
            end
        end -- End of "desktop" only clicks

        -- 2. Check for Clicks on Existing Windows (Close/Start Dragging/Bring to Front/Buttons)
        -- This logic runs in BOTH "desktop" and "endgame" states (for the report window).
        
        -- Iterate backwards (from end to start) to check the front-most windows first
        for i = #openWindows, 1, -1 do
            local win = openWindows[i]
            
            local currentWindowW, currentWindowH = getWindowDimensions(win.name) -- Get current size
            
            -- --- 2.1 Check for Close Button click ---
            local CloseButtonX = win.x + currentWindowW - CloseButtonW - 5
            local CloseButtonY = win.y + 5
            
            if isInside(x, y, CloseButtonX, CloseButtonY, CloseButtonW, TitleBarH - 5) then
                
                -- Prevent closing the end game report
                if win.name == "report" then
                    return
                end
                
                table.remove(openWindows, i) 
                if draggedWindowIndex == i then
                    isDragging = false
                    draggedWindowIndex = nil
                end
                return -- Stop checking, a window was closed
            end
            
            -- --- 2.2 Check for Title Bar Dragging area (Z-order and Drag Initiation) ---
            if isInside(x, y, win.x, win.y, currentWindowW, TitleBarH) then
                
                -- 1. Bring the clicked window to the front
                bringToFront(i)
                
                -- 2. Start drag on the now-front window
                draggedWindowIndex = #openWindows 
                local frontWin = openWindows[draggedWindowIndex]
                
                isDragging = true
                dragOffsetX = x - frontWin.x 
                dragOffsetY = y - frontWin.y
                
                return -- Drag started, stop checking windows
            end

            -- --- 2.3 Check for Content/Button Clicks (Z-Order only, OR button action) ---
            
            -- Check if the click is anywhere within the window's body
            if isInside(x, y, win.x, win.y + TitleBarH, currentWindowW, currentWindowH - TitleBarH) then
                
                -- 1. Bring it to the front
                bringToFront(i)
                local frontWin = openWindows[#openWindows] -- The window is now at the front
                
                -- Only check for button clicks if in "desktop" mode
                if gameState == "desktop" then
                
                    -- A. Check Final BUY Button (mycomp window)
                    if frontWin.name == "mycomp" then
                        local finalBtn = frontWin.FINAL_BUY_BUTTON
                        if finalBtn and finalBtn.active and isInside(x, y, finalBtn.x, finalBtn.y, finalBtn.w, finalBtn.h) then
                            executeCartTransaction()
                            return -- Transaction attempted
                        end
                        
                        -- B. Check Cart Adjustment Buttons
                        for key, btn in pairs(frontWin) do
                            if type(key) == 'string' and key:match("^cart_") then
                                if btn.active and isInside(x, y, btn.x, btn.y, btn.w, btn.h) then
                                    
                                    local itemName = btn.item
                                    local amountChange = btn.change
                                    local currentCart = shoppingCart[itemName] or 0
                                    
                                    local newCartAmount = currentCart + amountChange
                                    
                                    if newCartAmount == 0 then
                                        shoppingCart[itemName] = nil 
                                    else
                                        shoppingCart[itemName] = newCartAmount
                                    end
                                    
                                    return -- Button clicked
                                end
                            end
                        end
                    
                    -- C. Check for the per-item ON/OFF Switches (network window)
                    elseif frontWin.name == "network" then
                        
                        -- Loop through the switches stored by the draw function
                        for key, btn in pairs(frontWin.itemSellSwitches or {}) do
                            if isInside(x, y, btn.x, btn.y, btn.w, btn.h) then
                                local itemName = btn.item
                                itemSellSwitches[itemName] = not (itemSellSwitches[itemName] or false) 
                                return -- Switch clicked, stop checking
                            end
                        end
                    end
                
                end -- end of "desktop" only button checks
                
                -- If a body click happened (and didn't hit a button), the window is at the front. Stop the loop.
                return
            end
        end
    end
end

-- This function is required to stop dragging when the mouse is released.
function love.mousereleased(x, y, button, istouch, presses)
    if button == 1 then -- Left mouse button released
        if isDragging then
            isDragging = false
            draggedWindowIndex = nil
        end
    end
end
---

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
    
    -- 6. Draw Content 
    if win.name == "mycomp" then -- Call the Buy Window Content function
        drawBuyWindowContent(win, currentWindowW, currentWindowH)
    elseif win.name == "network" then -- Call the Sell Window Content function
        drawSellWindowContent(win, currentWindowW, currentWindowH)
    elseif win.name == "inbox" then
        drawNetworkWindowContent(win, currentWindowW, currentWindowH)
    elseif win.name == "briefcase" then
        drawBriefcaseWindowContent(win, currentWindowW, currentWindowH)
    elseif win.name == "info" then 
        drawInfoWindowContent(win, currentWindowW, currentWindowH)
    elseif win.name == "report" then -- 
    drawEndGameScreen(win, currentWindowW, currentWindowH) -- Call the new function
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
        
    elseif gameState == "desktop" or gameState == "endgame" then 

        -- --- Draw Taskbar (Always drawn in desktop or endgame)
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
        
        
        -- The rest of the desktop elements are only drawn if the game is NOT over
        if gameState == "desktop" then
            
            -- Draw the Timers in the bottom left
            if timeRemaining > 0 then
                love.graphics.setColor(0, 0, 0) -- Black text
                love.graphics.setFont(MenuF)
                
                local timerY = TaskBarStarty + TaskBarEndh/2 - MenuF:getHeight()/2 
                
                -- 1. Game Timer
                local timerText = "Time Left: " .. formatTime(timeRemaining)
                local gameTimerX = StartButx + StartButw + 15
                love.graphics.print(timerText, gameTimerX, timerY)
                
                -- 2. Market Refresh Timer
                local marketTimerText = "Next Supply Batch: " .. formatTime(batchTimer)
                local marketTimerX = gameTimerX + 150
                love.graphics.print(marketTimerText, marketTimerX, timerY)
                
                -- 3. Open Sell Timer 
                local sellTimerText = string.format("Open Sell: %02d", math.floor(sellTimer))
                local marketTimerW = MenuF:getWidth(marketTimerText)
                local sellTimerX = marketTimerX + marketTimerW + 15 
                
                love.graphics.print(sellTimerText, sellTimerX, timerY)
            end
            
            -- --- Draw Desktop Icons and Labels 
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
        end
        
        -- --- Draw Multiple Windows (Always drawn in desktop or endgame)

        for i, win in ipairs(openWindows) do
            drawWindow(win)
        end
        
        -- [THIS IS THE NEW LINE]
        -- Draw the menu if it's open (drawn after windows to appear on top)
        drawMenu()

        if failureMessage ~= "" then
            love.graphics.setFont(MenuF)
            local msgText = failureMessage
            
            -- Calculate position on the bottom right of the taskbar
            local msgW = MenuF:getWidth(msgText)
            local msgX = wln - msgW - 10 -- 10px from the right edge
            local msgY = TaskBarStarty + TaskBarEndh/2 - MenuF:getHeight()/2 

            
            -- Draw text (Red)
            love.graphics.setColor(1, 0, 0)
            love.graphics.print(msgText, msgX, msgY)
        end

        love.graphics.setColor(1, 1, 1) -- Final reset color
    end
end