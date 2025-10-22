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
have a another list beside the item, and this will be its new price and it will be coloured red or green depending if it went up a price or went down, and this will change every minute, and another key idea is sell stragety, by trying to sell, its probability of selling is dependent on the demand priorty. Sell cycle and buy cycel will be for every minute on the game timer. 
- Need to implement a range value dictionary control
- Randomise the sell value every minute
- Sell probility concept

But firstly new price range must be added then buy then briefcase then sell concepts.


**NOTE** I had a slight debate with my self, if I should use white text instead of black text below the icons.