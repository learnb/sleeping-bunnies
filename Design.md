# Design

## Overview

A stealth game.

## Entities

Rabbit - Player character.

Bunny - The Rabbit must keep them alive.

Food - Consumable. Gives the Rabbit energy.

Fox - Guards food. Will attack Rabbit when detected.

## Systems

**Rabbit Survival**

The Rabbit can only be harmed by the Fox. Being caught by the Fox results in a game over.

**Bunny Survival**

The Bunnies' health slowly depletes over time. The Rabbit feeds Bunnies by pressing X (green) when nearby. Feeding Bunnies depletes the Rabbit's energy. The Rabbit must find and eat food to restore its energy.

**Food**

Food only grows in certain areas. After consumed, food will respawn after a cooldown timer.

**Detection**

The Fox starts in the 'Idle' state but changes state when detecting the Rabbit. The Fox has scent range and a vision range that can detect the Rabbit. When the Rabbit is within the scent range the Fox becomes 'Alert'. When the Rabbit is within the vision range (and not hidden) the Fox will enter the 'Chase' state.

The behavior of the Fox during each state is as follows:

Idle: Patrols area

Alert: Walks towards its target.

Chase: Runs straight at its target with bloodlust.

**Hiding**

The Rabbit is always completely safe while in tall grass. However a Fox can still smell a hidden Rabbit, and will remain Alert until the Rabbit is no longer in its scent range.

**Sniffing Ability**

The Rabbit has a temporary ability with a cooldown that let's the player see the Fox's scent and vision range

## Controls

**Movement**: Buttons 0-4 (WASD, D-pad)

**Sniff**: Button 4 (Z, Red)

**Feed**: Button 5 (X, Green)

**Menu**: Button 4 & Button 5 ( Red & Green) at the same time

