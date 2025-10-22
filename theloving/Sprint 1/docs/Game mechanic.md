# Game Mechanic Document

This game is a business empire simulation.

I am not a fan of idle or AFK games, as I believe they lack engagement and purpose (useless). I also dislike overly easy games, as I prefer challenges that require skill and strategy (I still think its useless). With that in mind, I aim to create a game that is accessible yet engaging, focusing on strategic decision-making.

## Design Philosophy
My goal is to keep the game simple enough to be enjoyable, while still offering depth through strategic gameplay. The core mechanics will revolve around buying and selling, but with elements of randomness and prediction to keep the gameplay dynamic and challenging.

---

## Point 1: Strategy with Randomisation
I want the game to be both fun and strategic. To create this, I’ll incorporate randomness in the items and their demand. While the items and demand will be randomised, I will keep the variation within a controlled range to ensure players can predict trends and make informed decisions. The core gameplay will revolve around timing buy and sell actions to maximize their profits.

---

## Point 2: Limitations and Game Duration
To prevent endless trading and add a layer of challenge, the game will operate within time limits. Players will start a game session with a timer—choices of 15, 30, or 60 minutes—depending. The objective will be to accumulate as much net worth as possible within the allotted time, encouraging strategic planning and quick decision-making.

---

## Point 3: Additional Strategic Elements
To deepen the strategic aspect, I plan to include mechanics such as taxes and permits. These will introduce additional considerations for players, forcing them to weigh the costs and benefits of their actions and further enhance the complexity and engagement of the game.


# Game Start
- The game will present three timer options on the screen: **15 minutes**, **30 minutes**, and **60 minutes**.
- Once the player selects a timer, the game begins with a brief head start, allowing the player to prepare.

---

# Game Progression
The game will feature four main panels:

## 1. Sell Panel
- Allows players to sell items from their storage.
- Selling items will take some time, based on a duration that depends on the item.
- Taxes will be applied to sales, reducing the net profit.

## 2. Buy Panel
- Enables players to purchase items from the network.
- Purchase durations will vary depending on the item’s scale and value.
- Taxes will also be applied during buying.
  
## 3. Briefcase / Storage / Bank
- Acts as the player's storage for items.
- Players can purchase additional storage with taxes.
- Currently, no specific penalties for storage unless future mechanics include tax demand or storage limits.

## 4. Network
- Displays all available items in the game.
- Each item has:
  - A buy and sell duration.
  - A tax amount.
  - A quantity.
  - Demand priority.
  - A randomized buy and sell range, which constantly reshuffles.
- Items' demand and pricing fluctuate within a controlled range to keep gameplay strategic.
  (Depending on the item scales the randomisation will vary, example bananas wont vary in range unlike a TV)

---

# Game End
- When the timer runs out, the game concludes.
- The player will be shown:
  - Their total net worth based on the contents of their briefcase.
  - Overall statistics, possibly visualized through graphs.
  - Total taxes paid.
  - Money spent versus money saved or accumulated.

---

# Additional Ideas (Overflow)
- Implement automation or business management features, allowing players to set up passive income streams. (Maybe be added into Briefcase)
- Incorporate detailed graphs and analytics for better strategic insight.
- Pause game / save game
- Crash Game handling
- leaderboard
- toturial
- Difficulty change
- Bank