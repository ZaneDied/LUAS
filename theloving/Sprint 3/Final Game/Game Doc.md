# Script Documentation

## Variables and Initialization

Your script begins by initializing variables for window positions, sizes, UI elements, game states, timers, and market data. These variables control the game's flow, UI layout, and data management.

---

## Helper Functions

### `isInside(x, y, rx, ry, rw, rh)`
- **Purpose:** Checks whether a point `(x, y)` is within a rectangle defined by `(rx, ry, rw, rh)`.
- **Use:** Used extensively for detecting clicks on buttons, icons, and window regions.

---

## UI Rendering Functions

### `drawMenu()`
- **Purpose:** Renders the in-game menu when `isMenuOpen` is true.
- **Logic:**
  - Draws a background rectangle for the menu.
  - Populates menu options: "End", "Restart", "Info", "Continue".
  - Stores clickable button regions for mouse detection.
- **Comment Notes:** Draws options centered and stores their positions for interaction.

---

### `drawEndGameScreen(win, w, h)`
- **Purpose:** Renders the final report window after game ends.
- **Logic:**
  - Displays final stats such as starting capital, final cash, inventory value, net worth, items purchased/sold, earnings, and ratio.
  - Includes a simple bar chart to visualize buy/sell volume.
- **Comments:** Explains each line's purpose, e.g., drawing text, calculating positions, and rendering the graph.

---

### `drawInfoWindowContent(win, w, h)`
- **Purpose:** Renders the informational/help window.
- **Logic:**
  - Contains static help text explaining game mechanics.
  - Uses word wrapping to ensure text fits inside window borders.
  - Draws each paragraph with proper spacing.
- **Comments:** Clarifies text wrapping and layout logic.

---

### `drawWindow(win)`
- **Purpose:** Main function to draw any window based on its `win.name`.
- **Logic:**
  - Draws window body, title bar, close button.
  - Calls specific content drawing functions (`drawBuyWindowContent`, `drawSellWindowContent`, etc.) based on window type.
- **Comments:** Explains window structure, border, title, and content rendering.

---

### `drawBuyWindowContent(win, w, h)`
- **Purpose:** Renders the buy/sell items table within the "Buy" window.
- **Logic:**
  - Calculates dynamic column widths based on header and content.
  - Draws headers, data rows, and adjustment buttons (+1, -1, etc.).
  - Implements enabling/disabling buttons based on supply or cart constraints.
  - Calculates total transaction cost, displays total, and a final "BUY ITEMS" button.
  - Stores button regions for click detection.
- **Comments:** Explains layout, button positioning, and logic for adding/removing items from cart.

---

### `drawSellWindowContent(win, w, h)`
- **Purpose:** Displays inventory and auto-sell switches.
- **Logic:**
  - Calculates column widths based on header and inventory item names.
  - Shows "No items" message if inventory is empty.
  - For each item:
    - Displays item name, quantity, current price, total value.
    - Draws toggle switch for auto-sell.
  - Stores switch regions for interaction.
- **Comments:** Clarifies drawing logic, switch states, and inventory display.

---

### `drawNetworkWindowContent(win, w, h)`
- **Purpose:** Visualizes market data: current prices, projections, and supply.
- **Logic:**
  - Calculates column widths based on headers and data.
  - Draws headers and data rows for each market item.
  - Uses color coding to indicate price changes.
- **Comments:** Explains dynamic sizing, data rendering, and visual cues for market trends.

---

### `drawBriefcaseWindowContent(win, w, h)`
- **Purpose:** Shows financial overview and inventory summary.
- **Logic:**
  - Draws "Financial Summary" with current cash and net worth.
  - Draws "Inventory" with item names and quantities.
  - Adjusts width based on content length.
  - Displays "No items in inventory" if empty.
- **Comments:** Details calculation of widths and layout considerations.

---

## Core Logic Functions

### `executeCartTransaction()`
- **Purpose:** Processes the purchase based on cart contents.
- **Logic:**
  - Calculates total cost.
  - Checks if player has enough money.
  - Deducts amount, updates inventory, resets cart.
  - Sets success or failure message.
- **Comments:** Explains step-by-step purchase process and message handling.

---

### `calculateNetWorth()`
- **Purpose:** Calculates total player's net worth (cash + inventory value).
- **Logic:**
  - Sums current cash and item values based on market prices.
- **Comments:** Clarifies calculation for final stats.

---

### `calculateColumnWidths()`
- **Purpose:** Determines optimal widths for market data columns.
- **Logic:**
  - Measures header and data to find maximum width needed for each column.
- **Comments:** Ensures proper layout and prevents text overflow.

---

### `calculateBriefcaseWidth()`
- **Purpose:** Calculates dynamic width of the Briefcase window based on content.
- **Logic:**
  - Measures item names, quantities.
  - Ensures window is wide enough for all content or "No items" message.
- **Comments:** Explains layout flexibility.

---

### `calculateNextMarketProjections()`
- **Purpose:** Generates new projected prices and supply ranges for market items.
- **Logic:**
  - Randomizes projected prices within defined ranges.
  - Keeps demand constant from base data.
- **Comments:** Describes market fluctuation simulation.

---

### `refreshMarket()`
- **Purpose:** Updates market data, adding supply and updating prices.
- **Logic:**
  - Sets current prices to projected prices.
  - Adds supply based on supply range.
  - Calls projection calculation for next cycle.
- **Comments:** Explains market dynamics.

---

### `calculateFinalStats()`
- **Purpose:** Computes final game statistics for the report.
- **Logic:**
  - Calculates inventory value.
  - Computes net worth.
  - Derives buy/sell ratio.
  - Stores in `finalStats`.
- **Comments:** Clarifies statistical calculations and ratio handling.

---

## Window Management Functions

### `getWindowTitle(key)`
- **Purpose:** Returns window title based on internal key.
- **Logic:** Maps internal window identifiers to display titles.
- **Comments:** Simple utility for window labeling.

---

### `findWindowIndexByName(appName)`
- **Purpose:** Finds index of an open window by name.
- **Logic:** Searches `openWindows` array.
- **Comments:** Used for focus and management.

---

### `bringToFront(index)`
- **Purpose:** Moves a window to the top of the window stack.
- **Logic:** Removes from current position and appends to end.
- **Comments:** Ensures window focus order.

---

### `formatTime(seconds)`
- **Purpose:** Converts seconds into MM:SS format.
- **Logic:** Calculates minutes and seconds, formats string.
- **Comments:** Used for displaying timers.

---

## Game State Management

### `resetGame()`
- **Purpose:** Resets all game variables to initial states.
- **Logic:**
  - Resets game status, timers, windows, stats.
  - Re-initializes market data and inventory.
  - Starts fresh, ready for a new game.
- **Comments:** Explains resetting process for restart functionality.

---

## Main Love Callbacks

### `love.load()`
- **Purpose:** Initializes game state, loads assets, sets starting variables.
- **Logic:** Sets default window positions, fonts, loads images, and calls `resetGame()`.

### `love.update(dt)`
- **Purpose:** Manages timers, game logic, and state updates.
- **Logic:**
  - Counts down game timer; ends game when zero.
  - Updates market supply and prices periodically.
  - Handles auto-sell logic.
  - Manages message display timing.
  - Handles window dragging.
- **Comments:** Explains each timer and game state transition.

### `love.mousepressed(x, y, button, ...)`
- **Purpose:** Handles user interaction.
- **Logic:**
  - Detects clicks on selection screen buttons.
  - Opens/Closes windows.
  - Handles menu interactions.
  - Initiates window drag.
  - Handles button presses within windows (buy/sell adjustments, switches).
- **Comments:** Explains detection hierarchy and interaction flow.

### `love.mousereleased(x, y, button, ...)`
- **Purpose:** Stops dragging windows on mouse release.
- **Logic:** Sets `isDragging` to false and clears `draggedWindowIndex`.

### `love.draw()`
- **Purpose:** Renders all game visuals depending on game state.
- **Logic:**
  - Draws selection screen or desktop/endgame interface.
  - Draws taskbar, icons, windows, menu, messages.
- **Comments:** Explains drawing order, UI components, and dynamic content.

(I am not sure if I included everything)

# ERROR TESTING


| Feature Area             | Test Case             | Test Steps                                                                 | Expected Result                                                                 | Status |
|--------------------------|-----------------------|----------------------------------------------------------------------------|---------------------------------------------------------------------------------|--------|
| Core Game                | Start Game            | 1. Launch the game. 2. Click the "15 Minutes" button.                       | The selection screen disappears. The desktop, icons, and taskbar appear. Timers start counting down. | Pass   |
| Core Game                | Game End (Timer)      | 1. Let the "Time Left" timer run down to 00:00.                            | The desktop icons/timers hide. The "GAME OVER: FINAL REPORT" window appears. | Pass   |
| Core Game                | Game End (Menu)       | 1. Click 'MENU' -> 'End'. 2. Wait 5 seconds.                                | The "GAME OVER: FINAL REPORT" window appears.                                | Pass   |
| Core Game                | Restart Game          | 1. While in-game, click 'MENU' -> 'Restart'.                                | The game immediately returns to the "Select Game Duration" selection screen. | Pass   |
| New: Info Window         | Open Window           | 1. Click 'MENU'. 2. Click 'Info'.                                            | The "Help & Information" window opens.                                          | Pass   |
| New: Info Window         | Text Wrapping         | 1. Open the 'Info' window. 2. Read the content.                              | All text is contained inside the window borders. Long paragraphs wrap correctly and do not run off the screen. | Pass   |
| Window Mgmt              | Open All Windows      | 1. Click all 4 desktop icons (Buy, Sell, Network, Briefcase).             | All four windows open and are visible.                                          | Pass   |
| Window Mgmt              | Close Window          | 1. Click the 'X' button on the 'Buy' window.                                | The 'Buy' window closes.                                                        | Pass   |
| Window Mgmt              | Drag Window           | 1. Click and hold the blue title bar of the 'Sell' window. 2. Move mouse. | The 'Sell' window moves with the mouse.                                         | Pass   |
| Window Mgmt              | Z-Ordering (Focus)    | 1. Open 'Buy' and 'Sell' so they overlap. 2. Click any part of 'Buy'.     | The 'Buy' window moves to the front, on top of the 'Sell' window.             | Pass   |
| 'Buy' Window             | Add to Cart           | 1. Open 'Buy'. 2. Click +1 on 'Pen'.                                         | The 'Cart' column for 'Pen' shows 1. The 'Total Cost' updates. 'Net Cart Cost' updates. | Pass   |
| 'Buy' Window             | Successful Purchase   | 1. Add items to cart (e.g., 1 'Pen'). 2. Click 'BUY ITEMS'.                | "PURCHASE SUCCESSFUL" message appears. Cash decreases. Cart clears.          | Pass   |
| 'Buy' Window             | Failed Purchase       | 1. Add items until 'Net Cart Cost' > 'Current Cash'. 2. Click 'BUY ITEMS'.| "PURCHASE FAILED" message appears. Cash remains unchanged. Cart not cleared. | Pass   |
| 'Sell' Window            | Toggle Auto-Sell      | 1. Open 'Sell'. 2. Click 'OFF' switch for 'Pen'. 3. Click again.          | Switch toggles to 'ON' (green). Then back to 'OFF' (gray).                   | Pass   |
| 'Sell' Window            | Auto-Sell Logic       | 1. Turn 'ON' switch for 'Pen'. 2. Wait for 'Open Sell' timer to hit 00. | "AUTO-SOLD" message appears. Cash increases. 'Pen' inventory decreases. (May take a few tries due to demand check). | Pass   |
| 'Sell' Window            | Empty Inventory       | 1. Sell your last 'Pen'. 2. Open 'Sell' window.                            | Table shows "No tradable items in inventory".                                | Pass   |
| 'Network' Window         | Market Update         | 1. Open 'Network'. Note 'Current Price' and 'Projected Price'. 2. Wait for 'Next Supply Batch' timer. | 'Current Price' updates to previous 'Projected Price'. New 'Projected Price' appears. | Pass   |
| 'Briefcase' Window       | Data Sync (Buy)       | 1. Buy 5 'Erasers'. 2. Open 'Briefcase'.                                    | 'Inventory' shows 'Eraser' with Quantity 5. 'Current Cash' and 'Net Worth' update. | Pass   |
| 'Briefcase' Window       | Data Sync (Sell)      | 1. Auto-sell 1 'Pen'. 2. Open 'Briefcase'.                                 | 'Inventory' shows 'Pen' with Quantity 0. 'Current Cash' and 'Net Worth' update. | Pass   |
| 'Report' Window          | Final Stats           | 1. End the game. 2. View 'Report' window.                                   | All stats (Net Worth, Items Sold, etc.) are displayed correctly.            | Pass   |
| 'Report' Window          | No Close              | 1. End the game. 2. Click 'X' on 'Report' window.                          | Window does not close.                                                        | Pass   |


---

# Welcome to the School Supply Market!

The goal is to make as much money as possible before the time runs out. Buy low, sell high!

---

## Window Guide

### 1. Buy (Computer Icon):
This is the main market where you buy items. Use the +/- buttons to add items to your cart. The **'Cart'** column shows how many you are buying. You can only buy items if there is enough supply in the market. Click **'BUY ITEMS'** at the bottom to complete the purchase.

### 2. Sell (Server Icon):
This window shows your current inventory and its value. This is where you set up auto-selling. Click the **'Switch'** to turn it ON or OFF for an item. When ON, the game will try to sell 1 unit of that item every 5 seconds (as per the **'Open Sell'** timer). A sale is only successful if it passes a **'demand check'**.

### 3. Network (Inbox Icon):
This is your market intelligence report. **'Current Price'** is what items cost right now. **'Projected Price'** is what the price will be after the next supply batch. **'Demand (1-10)'** (e.g., 9) indicates a higher chance to auto-sell. **'Current Supply'** is how many units are available to buy in the **'Buy'** window.

### 4. Briefcase (Briefcase Icon):
Shows your **'Financial Summary'** and **'Inventory'**. **'Net Worth'** = Your Current Cash + Total Value of all items in your inventory.

---

## Timers (on Taskbar)

- **Time Left:** The main game timer. When it hits 0, the game ends.
- **Next Supply Batch:** When this hits 0, the market updates (Projected prices become current, and new supply is added).
- **Open Sell:** How often the game checks to auto-sell items (if switched ON).