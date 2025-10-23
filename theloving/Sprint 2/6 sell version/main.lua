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

-- Market Fluctuation Variables
-- CONFIGURABLE SUPPLY BATCH TIME
local supplyBatchInterval = 60 -- Time between supply additions/price range updates in seconds (Default 1 minute)
local batchTimer = supplyBatchInterval

-- Player Financial and Inventory Data
local defaultStartingMoney = 500 -- <-- Change value to adjust the starting money (e.g., 500, 1000, etc.)
local currentMoney 
local inventory = {} -- Stores how many units of each item the player owns
local networkLog = {} -- NEW: Initialize the log of network events for the 'inbox' window.

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

-- Global variables for the new Buy window UI elements
local BuyButtonW = 30 -- INCREASED WIDTH for the +1, -1, etc. buttons
local BuyButtonH = 24 -- INCREASED HEIGHT
local AmountColW = 80 -- Width for the new 'Amount' (Total Cost/Value) column
local CartColW = 80 -- NEW: Width for the Cart Change column
local BuyButtonSpacing = 5 -- Space between buttons and columns
local shoppingCart = {}

-- Helper function to execute the full cart transaction
local function executeCartTransaction()
    local totalCost = 0
    local canAfford = true
    local canFulfillSupply = true
    
    -- 1. Calculate total cost and check constraints
    for itemName, cartAmount in pairs(shoppingCart) do
        local data = marketData[itemName]
        if data then
            local price = data.currentPrice
            if cartAmount > 0 then -- Buying
                totalCost = totalCost + (price * cartAmount)
                if data.currentSupply < cartAmount then
                    canFulfillSupply = false
                    break
                end
            elseif cartAmount < 0 then -- Selling
                local playerHas = inventory[itemName] or 0
                if playerHas < math.abs(cartAmount) then
                    canFulfillSupply = false -- Player doesn't have enough to sell
                    break
                end
                -- Selling adds money, so subtract cost from totalCost to get final net change
                totalCost = totalCost - (price * math.abs(cartAmount))
            end
        end
    end

    if totalCost > currentMoney and canAfford then -- Check affordability
        canAfford = false
    end
    
    -- 2. Execute transaction or show error
    if canAfford and canFulfillSupply then
        
        -- Execute all trades
        for itemName, cartAmount in pairs(shoppingCart) do
            local data = marketData[itemName]
            
            if cartAmount > 0 then -- Buying
                inventory[itemName] = (inventory[itemName] or 0) + cartAmount
                data.currentSupply = data.currentSupply - cartAmount
            elseif cartAmount < 0 then -- Selling
                local amountToSell = math.abs(cartAmount)
                inventory[itemName] = inventory[itemName] - amountToSell
                data.currentSupply = data.currentSupply + amountToSell
            end
        end
        
        -- Update money (totalCost is a net value, positive if buying, negative if selling)
        currentMoney = currentMoney - totalCost
        
        -- Clear the cart after successful transaction
        shoppingCart = {}
        
        -- Success Message (Optional: you can add a success message here too)
        failureMessage = "Transaction successful!" 
        messageDuration = 3 -- Display for 3 seconds
        
        return true
    else
        if not canAfford then
            -- Set the global message and duration
            failureMessage = "Transaction failed: Not enough cash."
        elseif not canFulfillSupply then
            -- Set the global message and duration (the one you asked about)
            failureMessage = "Transaction failed: Insufficient supply/inventory."
        end
        messageDuration = 5 -- Display for 5 seconds
        
        return false
    end
end

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


-- Update the getWindowDimensions function to use the new content width.
local function getWindowDimensions(name)
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
        
    elseif name == "network" then -- NEW: Sell Window Dimensions
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


    end
    return w, h
end

local function drawBuyWindowContent(win)
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
    local cartChangeHeader = "Cart" -- NEW HEADER
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
    
    -- Column 3: Cart Change (NEW Column Header)
    local cartTextW = MenuF:getWidth(cartChangeHeader)
    local cartTextX = cartColX + (CartColW/2) - (cartTextW/2)
    love.graphics.print(cartChangeHeader, cartTextX, headerY)
    
    -- Column 4: Total Cost (New Column Header)
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
    local FinalButtonX = win.x + winW - BuyButtonW_Final - 10 
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
local function drawSellWindowContent(win)
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
    
    -- NEW: Fixed width for the SELL button/input
    local sellColW = 100 
    local SellButtonW = sellColW - 10 -- Button width within the column
    local SellButtonH = itemHeight - 4 -- Button height
    local SellButtonText = "Sell All" -- Button text

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
        totalWidth = math.max(totalWidth, noItemsTextW)
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
    
    love.graphics.print("Sell", currentX + 5, headerY) -- Header for Sell column

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

    contentY = contentY + itemHeight
    
    -- --- 3. Draw Data Rows ---
    local rowCounter = 0
    local currentItemIndex = 1

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
                
                -- Column 5: SELL button area
                local buttonY = contentY + 2 -- Small margin
                local buttonX = currentX + 5
                
                -- --- DRAW SELL ALL BUTTON ---
                local buttonKey = string.format("sell_%d", currentItemIndex)
                
                -- Check if the button is active (only active if count > 0)
                local isSellActive = count > 0
                
                -- Store button data for click detection
                win[buttonKey] = {
                    item = itemName,
                    x = buttonX,
                    y = buttonY,
                    w = SellButtonW,
                    h = SellButtonH,
                    active = isSellActive
                }
                
                -- Draw Button Background (Red by default, Green if active)
                if isSellActive then
                    love.graphics.setColor(0/255, 150/255, 0/255) -- Green
                else
                    love.graphics.setColor(180/255, 0/255, 0/255) -- Red (as per request, but usually disabled buttons are grey)
                end

                -- To fulfill the 'red on default and green on click' request, 
                -- we'll interpret 'default' as 'not having been clicked *yet*'. 
                -- We'll make it RED if there's inventory, but make the active color GREEN.
                -- For the sake of demonstration, I will use RED for Active and DARKER RED for Inactive
                -- unless the user meant "Green when the condition is met to sell (active)".
                -- Sticking to the request: RED by default, but it's *active* only if count > 0.
                if isSellActive then
                    love.graphics.setColor(180/255, 0/255, 0/255) -- RED for active/default
                else
                    love.graphics.setColor(150/255, 150/255, 150/255) -- Grey for inactive
                end

                -- If the button data is present (from a previous click, which it won't be in a simple draw loop), 
                -- you'd check a "isHovered" or "isClicked" state to change the color.
                -- For a simple implementation, we'll use the active state to choose Red/Green.
                -- I'll use Green for active (can sell) and Red for inactive (cannot sell).
                if isSellActive then
                    love.graphics.setColor(0/255, 150/255, 0/255) -- Green when active/can sell
                else
                    love.graphics.setColor(180/255, 0/255, 0/255) -- Red when inactive/cannot sell
                end

                love.graphics.rectangle("fill", buttonX, buttonY, SellButtonW, SellButtonH)

                -- Draw Button Border
                love.graphics.setColor(0, 0, 0)
                love.graphics.rectangle("line", buttonX, buttonY, SellButtonW, SellButtonH)

                -- Draw Button Text (White)
                love.graphics.setColor(255, 255, 255) 
                local textWidth = MenuF:getWidth(SellButtonText)
                local textX = buttonX + (SellButtonW/2) - (textWidth/2)
                love.graphics.print(SellButtonText, textX, buttonY + 2) 
                
                -- Draw lines
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
                currentItemIndex = currentItemIndex + 1
            end
        end
    else
        -- Draw 'No items' row - When inventory is empty
        love.graphics.setColor(255/255, 255/255, 255/255) -- White background
        love.graphics.rectangle("fill", startX, contentY, totalWidth, itemHeight)
        
        love.graphics.setColor(0, 0, 0)
        
        -- Print the text centered within the totalWidth
        local textToPrint = noItemsText
        local textW = MenuF:getWidth(textToPrint)
        love.graphics.print(textToPrint, 
            startX + totalWidth / 2, 
            contentY + 2, 
            0, 1, 1, 
            textW / 2, -- X-Origin: Use half the text width to center
            0 -- Y-Origin
        )
        
        love.graphics.rectangle("line", startX, contentY, totalWidth, itemHeight)
    end
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
local function drawBriefcaseWindowContent(win)
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

    if messageDuration > 0 then
        messageDuration = messageDuration - dt
        if messageDuration <= 0 then
            failureMessage = "" -- Clear the message when time runs out
        end
    end
    
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
                
                -- FIX: Use modulo on staggerCount to prevent drift and wrap stacking effect
                local safeStagger = staggerCount % 5 -- Stacks up to 5 windows deep (0, 1, 2, 3, 4) then wraps back to 0
                local offsetAmount = safeStagger * 20 
                
                staggerCount = staggerCount + 1 -- Increment the offset counter for the *next* window

                -- Create a new window object and insert it at the end of the array
                local winW, winH = getWindowDimensions(clickedIcon)
                table.insert(openWindows, {
                    name = clickedIcon,
                    x = wln / 2 - winW / 2 + offsetAmount, -- Apply the safe, wrapped offset
                    y = wht / 2 - winH / 2 + offsetAmount, -- Apply the safe, wrapped offset
                    active = true 
                })
                return -- Exit early after opening a window
            end
        end

        -- 2. Check for Clicks on Existing Windows (Close/Start Dragging/Bring to Front/Buttons)
        -- Iterate backwards (from end to start) to check the front-most windows first
        for i = #openWindows, 1, -1 do
            local win = openWindows[i]
            
            local currentWindowW, currentWindowH = getWindowDimensions(win.name) -- Get current size
            
            -- --- 2.1 Check for Close Button click ---
            local CloseButtonX = win.x + currentWindowW - CloseButtonW - 5
            local CloseButtonY = win.y + 5
            local cX1 = CloseButtonX
            local cY1 = CloseButtonY
            local cX2 = CloseButtonX + CloseButtonW
            local cY2 = CloseButtonY + TitleBarH - 5 

            if x >= cX1 and x <= cX2 and y >= cY1 and y <= cY2 then
                table.remove(openWindows, i) 
                if draggedWindowIndex == i then
                    isDragging = false
                    draggedWindowIndex = nil
                end
                return -- Stop checking, a window was closed
            end
            
            -- --- 2.2 Check for Title Bar Dragging area (Z-order and Drag Initiation) ---
            local titleX1 = win.x
            local titleY1 = win.y
            local titleX2 = win.x + currentWindowW 
            local titleY2 = win.y + TitleBarH

            if x >= titleX1 and x <= titleX2 and y >= titleY1 and y <= titleY2 then
                
                -- 1. Bring the clicked window to the front
                bringToFront(i)
                
                -- 2. Start drag on the now-front window
                draggedWindowIndex = #openWindows -- This is always the correct index after bringToFront
                local frontWin = openWindows[draggedWindowIndex]
                
                isDragging = true
                dragOffsetX = x - frontWin.x -- Calculate offset based on the actual object's x/y
                dragOffsetY = y - frontWin.y
                
                return -- Drag started, stop checking windows
            end

            -- --- 2.3 Check for Content/Button Clicks (Z-Order only, OR button action) ---
            
            -- Check if the click is anywhere within the window's body
            if x >= win.x and x <= win.x + currentWindowW and y >= win.y + TitleBarH and y <= win.y + currentWindowH then
                
                -- 1. Bring it to the front
                bringToFront(i)
                local frontWin = openWindows[#openWindows] -- The window is now at the front
                
                -- A. Check Final BUY Button (mycomp window)
                if frontWin.name == "mycomp" then
                    local finalBtn = frontWin.FINAL_BUY_BUTTON
                    if finalBtn and finalBtn.active and x >= finalBtn.x and x <= finalBtn.x + finalBtn.w and y >= finalBtn.y and y <= finalBtn.y + finalBtn.h then
                        executeCartTransaction()
                        return -- Transaction attempted
                    end
                    
                    -- B. Check Cart Adjustment Buttons
                    for key, btn in pairs(frontWin) do
                        if type(key) == 'string' and key:match("^cart_") then
                            if btn.active and x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
                                
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
                
                -- C. Check SELL All Buttons (network window)
                elseif frontWin.name == "network" then
                    for key, btn in pairs(frontWin) do
                        if type(key) == 'string' and key:match("^sell_") then
                            if btn.active and x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
                                
                                local itemName = btn.item
                                local amountToSell = inventory[itemName] or 0
                                
                                if amountToSell > 0 then
                                    local data = marketData[itemName]
                                    local currentPrice = data and data.currentPrice or 0
                                    local earnedMoney = amountToSell * currentPrice
                                    
                                    -- Execute sale
                                    currentMoney = currentMoney + earnedMoney
                                    inventory[itemName] = 0 -- Clear inventory for this item
                                    
                                    -- Add supply back to the market (representing the sale)
                                    if data then
                                        data.currentSupply = data.currentSupply + amountToSell
                                    end
                                    
                                    print(string.format("Sold all %d units of %s for $%.2f. Cash: $%.2f", 
                                                        amountToSell, itemName, earnedMoney, currentMoney))
                                end
                                
                                -- After the sale, re-run draw for Sell window content on next frame
                                -- No explicit redraw needed, the love.draw loop will handle it
                                
                                return -- Button clicked
                            end
                        end
                    end
                end
                
                -- If a body click happened (and didn't hit a button) or it's a non-button window, 
                -- the window is now at the front. Stop the loop.
                return
            end
        end
    end
end

-- FIX: This function is required to stop dragging when the mouse is released.
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
        drawBuyWindowContent(win)
    elseif win.name == "network" then -- NEW: Call the Sell Window Content function
        drawSellWindowContent(win)
    elseif win.name == "inbox" then
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

        if failureMessage ~= "" then
            love.graphics.setFont(MenuF)
            local msgText = failureMessage
            
            -- Calculate position on the bottom right of the taskbar
            local msgW = MenuF:getWidth(msgText)
            local msgX = wln - msgW - 10 -- 10px from the right edge
            local msgY = TaskBarStarty + TaskBarEndh/2 - MenuF:getHeight()/2 
            
            -- Draw background box (Black)
            love.graphics.setColor(0, 0, 0, 0.8) -- Semi-transparent black
            local boxX = msgX - 5
            local boxW = msgW + 10
            local boxH = MenuF:getHeight() + 4
            love.graphics.rectangle("fill", boxX, msgY - 2, boxW, boxH)
            
            -- Draw text (Red)
            love.graphics.setColor(1, 0, 0)
            love.graphics.print(msgText, msgX, msgY)
        end

        love.graphics.setColor(1, 1, 1) -- Reset color
    end
end