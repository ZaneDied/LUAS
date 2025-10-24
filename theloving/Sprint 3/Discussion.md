## Over flows
- Incorporate detailed graphs and analytics for better strategic insight
- Pause game / save game
- Crash Game handling
- leaderboard
- toturial
- Sell 2 version

So firstly I want to try fix the sell version 2, and then work on the end screen and pause, save. Then the tutorial maybe a video.

Delete the sell mechanics

### Sell game mechanic 2
- A new timer updating 10 (can be changed later on)
- The sell button is now an off and on switch
- Every 10 seconds the 1 item will be sold, but all dependent on its demand rate


**NOTE** I reorganised the love.update to be more readable for me atleast.

# Project Update Summary

## Progress Highlights
- Successfully finished the **Open Sell** feature — feeling proud of this milestone! 🎉
- Cleaned up and optimized some of the code, removing redundancies and improving readability.

## End Screen & Timer Logic
- Completed the final **end screen window** that appears when the game timer runs out.
- When the timer expires, the **receipt-style end window** spawns in seamlessly.
- Simplified the flow by **removing the icons and selling logic** after the timer ends:
  - Players can still buy items (waste their money), but it only affects their stats.
  - Selling is disabled, ensuring no further transactions impact the game state.

## Menu Bar & Tutorial Integration
- Implemented a **menu bar** with options:
  - **End** (triggered by depleting the timer to 5 seconds)
  - **Restart**
  - **Information / Tutorial**
  - **Continue** (resumes from pause)
- To handle the **End** action, instead of creating a new function, I simply set the **timer to 5 seconds** to trigger the end sequence naturally.

## Final Touches & Functionality
- All features are now **working smoothly**.
- Everything is integrated, including:
  - End, Restart, Info/Tutorial, and Continue options.
- The game flow feels polished and cohesive.

## Notes
- I didn’t document every change in detail due to time constraints.
- Focused on fixing issues and ensuring everything runs correctly, rather than extensive commenting.

---

**Overall, I'm very satisfied with the progress and the current state of the project**

# END SPRINT


**NOTE** I left some of the comments for me, because I was unbothered to delete them.