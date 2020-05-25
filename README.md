# Sleeping Bunnies
A Pico-8 game made for RNDGAME Jam 2020.

## Description
An endless-mode stealth game. The player's goal is to keep the sleeping bunnies alive. Increase your score by collecting carrots, feeding the bunnies, and keeping the bunnies alive.

## Controls
Movement: Buttons 0-4 (WASD, d-pad)

Sniff: Button 4 (Z, Blue)

Feed: Button 5 (X, Green)

Menu: Button 4 & Button 5 ( Blue & Green)

## Systems
**Rabbit Survival**

The Rabbit can only be harmed by the Fox. Being caught by the Fox results in a game over. However, the Rabbit cannot be harmed while it is hidden.

**Bunny Survival**

The Bunnies' health slowly depletes over time. The Rabbit feeds Bunnies by pressing X (green) when nearby. Feeding Bunnies depletes the Rabbit's energy. The Rabbit must find and eat food to restore its energy.

**Food**

Food only grows in certain areas. After consumed, food will respawn after a cool-down timer.

**Detection**

The Fox starts in the 'Idle' state but changes state when detecting the Rabbit. The Fox has scent range and a vision range that can detect the Rabbit. When the Rabbit is within the scent range the Fox becomes 'Alert'. When the Rabbit is within the vision range (and not hidden) the Fox will enter the 'Chase' state.

The Fox will target the Rabbit (if visible) otherwise it will target the Rabbit's scent (last known location).
The behavior of the Fox during each state is as follows:

*Idle*: Patrols area

*Alert*: Walks towards its target.

*Chase*: Runs straight at its target with bloodlust.

**Hiding**

The Rabbit is always completely safe while in tall grass. However a Fox can still smell a hidden Rabbit, and will remain Alert until the Rabbit is no longer in its scent range.

**Sniffing Ability**

The Rabbit has a temporary ability with a cool-down that let's the player see the Fox's scent range and vision range, as well as the Rabbit's scent.