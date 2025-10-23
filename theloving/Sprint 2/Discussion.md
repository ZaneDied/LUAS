Sprint 2

# Additional Ideas (Overflow)
- Implement automation or business management features, allowing players to set up passive income streams. (Maybe be added into Briefcase)
- Incorporate detailed graphs and analytics for better strategic insight.
- Pause game / save game
- Crash Game handling
- leaderboard
- toturial
- Difficulty change


In this sprint, I will focus on expanding my game mecahnics. Adding the items in shop, and implementing a start timer within the menu bar, and address overall overflow from last sprint.

## Item Shop Development

To simplify the process, I will focus primarily on the **Network App** first, and then expand to the **Buy App**, **Sell App**, and eventually the **Briefcase**.

Items will have a randomized range value and will vary based on priority and time. 

### Approach and Considerations
- There will be a variety of items to include in the game, which creates a challenge in managing diversity.
- To make development easier, I will create a specific theme for the game—initially, a **School** theme.
- In future versions, I plan to introduce additional themes to diversify the items further.
- For now, the focus is on making the items relevant to the theme and straightforward to implement.


## Next Steps

After implementing the item shop and expanding the network app, I will shift my focus to:

- Developing the **Buy Items** and **Sell Items** functionalities.
- Implementing the **Timer**.

**NOTE** TO make my life easier Im first doing it in pseudo code

**BUG FOUND** So there is this bug where when I close and open a window it sways to the right eventually not letting me open the window because its unreachable. (result to overflow)

# Project Update

## Table
- An Excel-style table has been created, with detailed pseudocode included. (Best part is I made it into a dictionary list)

## Timer
- Timer screen has been integrated.
- Code has been restructured for better readability.
- The menu bar has been realigned.
- A countdown timer has been added beside the menu bar.
- All writen into pseudocode.

**NOTE** The menu bar is kinda useless, I will add the pause and save feature into the menu, but I cant really pause and save anything when nothing is being played. (meaning the next step is to add playability, which is the sell and buy)

## Game mechanic refinement
- Every minute, market prices will fluctuate within a specified range.
- Implement a range control dictionary to manage price variation ranges.
- Track available amount supply for each item.
- Incorporate demand-based probability for buying items.

# Existing Idea

- Add a new column beside the item list for the **new price**:
  - Display the projected price that updates every minute.
  - Color the price red if it has decreased, green if it has increased.
- Add a **net supply** column:
  - This will be a variable that resets or updates every minute.
  - It will accumulate supply over time and decrease when items are bought.
- Implement a **sell strategy**:
  - The probability of selling an item depends on its **demand priority**.
  - The selling cycle and buying cycle will operate every minute based on the game timer.
- Additional features to implement:
  - **Range value dictionary control** for price and supply fluctuations.
  - Randomize the **sell value** every minute.
  - Incorporate a **sell probability** concept based on demand and other factors.

---

## Development flow:
1. Add a **new price range** for items.
2. Implement the **buy** mechanic.
3. Develop the **briefcase** system.
4. Introduce the **sell** concept, making it strategic for players:
   - Players can save supply to sell later at higher projected prices (similar to crypto trading, but the difference is that priority is curccial since selling is dependent on the market priority).

---

**Notes**
- Scraped the whole game mechanic (not literarly) but now it will primarily focus on a **buy table** mechanic, emphasizing strategy.
- The projected price for the next market refresh encourages players to plan supply and sales.
- **Text color debate**:
  - Consider whether to use **white text** instead of **black text** below icons for better visibility or aesthetic preference.
- Window Bug (please fix future me)
- At this time range price table has been created.

### Game Flow Update

- **Briefcase**:  
  - Manage storage of purchased items.  
  - Cannot sell items if storage is empty.

- **Buy**:  
  - Purchase items to add to the briefcase for future sale.

- **Sell**:  
  - Sell items from the briefcase based on demand and projected prices.  
  - Selling depends on having items in storage.

**Sequence**: Briefcase → Buy → Sell  **VERY IMPORTNAT** because I can not really sell anything if theres nothing to buy.

### Game Mechanics update
- Still implementing the probability sell but on a refresh rate of every 5 seconds
- Kinda annoyed how I have to click on the title bar (remember the window bug)

I have just created the buy version, and that was probably the hardest part to do since I had to figure out how to style it and also its logic. I also kept getting confused by my own code, but it was later resolved by re-following my pseudo code. 

I do not want to touch my program if it works — it works. It might not be the tidiest anymore, and I may have changed too much stuff. But again, if it works it works. (There might be some font text error, I cannot be bothered to check all of it.)

Theres a bug, on top window bug, I may have tweak the logic to much and maybe have broke the logic, I have tested and rexamine the code, I have changed quite a few within the buy and sell version, and a working window would be briefcase version and below. I did some comparrison, between the 2 codes where that there was a implementation of new padding and I think my z cords were getting confused, I have fix the window click logic love.mousepressed 

Clicking a title bar immediately brings that window to the front AND starts the drag instantly.

Clicking the window body (including buttons) brings that window to the front to handle the action.

I have also included the display fixes for the Network window you requested in the previous step.

**NOTE** Also fixed the anoyance of clicking the title bar

after making the first ever working game
I tried to work on the second version of selling game
and I tried to make the windows very adaptable on the tables and I think I ended up messing up something. Because Ive been replacing and remaking and replace parts of the code to fit perfectly without changing much of the variables.

I give up, I cant get to fix it, I have done to much stuff so il over flow the sell version 2 to the next sprint and work on the menu and save, since I have already fix the bugs of window disapearing and window active.