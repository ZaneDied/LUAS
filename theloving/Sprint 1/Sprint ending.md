Initialize variables:
  - Window dimensions, positions, icons, and images
  - Open windows array
  - Dragging state variables
  - UI layout parameters (taskbar, buttons, fonts)

Define utility functions:
  - getWindowTitle(key): returns window title based on app name
  - findWindowIndexByName(appName): returns index of open window with given name
  - bringToFront(index): moves specified window to the front of rendering order

On love.load:
  - Set background color
  - Get window width and height
  - Load images for icons
  - Calculate font sizes and text widths
  - Set positions for icons and taskbar/buttons

On love.update(dt):
  - If dragging, update the position of the dragged window based on mouse movement

On love.mousepressed(x, y, button):
  - If left button:
    - If not dragging:
      - Check if an icon was clicked:
        - If clicked and window not open:
          - Add new window to openWindows at offset position
      - Else check if a window was clicked:
        - If clicked on close button:
          - Remove window
        - Else if clicked on title bar:
          - Bring window to front
          - Start dragging with mouse offset

On love.mousereleased(x, y, button):
  - Stop dragging

Draw functions:
  - drawWindow(win):
    - Draw window body, title bar, title text
    - Draw close button with 'X'
    - Draw window border

love.draw:
  - Draw taskbar and start button
  - Draw desktop icons and labels
  - Draw all open windows in order


---

## Key Test Scenarios & Results

| Test ID | Feature Tested | Description | Expected Result | Actual Result | Status |
| :---: | :--- | :--- | :--- | :--- | :---: |
| **T01** | **Critical Bug Fix** | Verify the original crash caused by `love.math.getOrderedKeys` is gone. | Application loads successfully without crashing on icon click. | Application loads and opens windows without error. | **PASS** |
| **T02** | **Multi-Window Opening** | Click all four desktop icons sequentially. | Four distinct windows (My Computer, Network, Inbox, Briefcase) open without errors. | All four windows open and exist simultaneously in the `openWindows` array. | **PASS** |
| **T03** | **Staggering Logic** | Observe the initial position of the four opened windows. | Each subsequent window is offset by (20, 20) pixels relative to the previous one. | Staggering is correctly applied using `staggerCount`. | **PASS** |
| **T04** | **Window Closing** | Click the 'X' button on any open window. | The window is removed from the screen and the `openWindows` array immediately. | Window is successfully removed using `table.remove`. | **PASS** |
| **T05** | **Layering (Bring to Front)** | Open two windows (A then B). Click A's title bar. | Window A immediately draws on top of Window B. | The `bringToFront` logic successfully moves the clicked window to the end of the array. | **PASS** |
| **T06** | **Draggability and Focus** | Click and hold the title bar of a window, then drag the mouse. | The window moves smoothly with the mouse and does not snap back to its original position. | Dragging is smooth, handled correctly in `love.update`, and the window stays under the cursor (due to offset calculation). | **PASS** |

---
