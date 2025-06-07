# Second Chance: Survive Zombie Bites with Prompt First Aid

Second Chance: Survive Zombie Bites with Prompt First Aid aims to make medical occupations and first aid more useful, and gives players a chance to survive zombie bite infections through saving throws, influenced by their traits, skills, occupations, and actions. When bites are 100% guaranteed death, most players opt for bleach which is very anticlimatic and
players would rarely see the effects of the infection. This mod adds depth to the infection system, making it more engaging and rewarding for players who prepare and act quickly while also adding the tension of wondering if you will survive.

This mod uses Dungeons and Dragons (D&D) style dice rolls to determine if players will live or die.

---
## TL;DR How to survive
When you are bitten, disinfect the wound with something like a bottle of disinfectant or alchohol swabs, or alchohol soaked cotton balls, or whatever else the game considers a disinfectant, but those are the 3 items I know should work. Poutices wont work.

The sooner you do this, the more likely you are to survive the bite. Every second counts.

## How It Works

1. **Infection Detection**:
   - This mod detects when the player becomes infected through a bite.
   - Infection start time and vector (e.g., bite) are recorded.

2. **Saving Throw Mechanics**:
   - Every ingame minute (2.5s IRL at default day length), the mod checks if the player has treated their wounds.
   - If wounds are treated, the player rolls a saving throw to determine survival.
   - The saving throw is influenced by:
     - **Occupation**: Doctors (+5) and nurses(+3) have higher bonuses. The following are +1 to saving throws {"policeofficer", "fireofficer", "parkranger", "veteran", "securityguard"}
     - **Traits**: Traits like `Resilient` and `Lucky` improve the roll, adding 1 for each trait up to a max of +3. The following traits improve rolls: {"FirstAid", "FastHealer", "Resilient", "ThickSkinned", "Dextrous", "Strong", "Athletic", "Outdoorsman", "Lucky"}
     - **First Aid Skill**: Higher skill levels provide additional bonuses starting at first aid level 6 giving +1 for each level up to a max of +5
    - Total max bonus saving throws at time of writing this document is +13

3. **Dynamic Difficulty**:
   - The base DC (Difficulty Class) is 16, with no bonus occupation, trait or skill level bonus saving throws, is a 20% chance of survival, and ~70% chance with all bonuses, at 0 ingame minutes elapsed.
   - The DC increases by 1 for every 3 ingame minutes of untreated infection.
   - After 1 ingame hour, the DC becomes impossible to beat.

4. **Critical Rolls**:
   - In D&D fashion with critical rolls:
   - Rolling a natural 20 restores endurance and fatigue as a bonus.
   - Rolling a natural 1 player becomes stressed, unhappy and drunk.

5. **Advantaged Rolls**:
   - Roll the die twice, and pick the higher number. If the lucky trait were stille around I would have tied this to that, but for now it's just going to be a sandbox

6. **Infection Resolution**:
   - If the player succeeds the saving throw, the infection is cured, and all infection-related data is reset.
   - If the player fails, they are marked for death.

---

## Code Overview

### Key Functions

- **`LoadPlayerData`**:
  - Initializes the player and mod data when the game starts.

- **`ResetInfectionData`**:
  - Resets infection-related data when a new character is created or respawned.

- **`calculateBonusSavingThrow`**:
  - Calculates the player's saving throw bonus based on their occupation, traits, and First Aid skill.

- **`calculateDifficultyClass`**:
  - Determines the DC for the saving throw based on the time elapsed since infection.

- **`checkUntreatedBiteWounds`**:
  - Checks if the player has untreated bite wounds.

- **`checkDoesPlayerSurvive`**:
  - Rolls a d20 and determines if the player survives the infection based on their total roll and the DC.

- **`playerWillSurvive`**:
  - Cures the infection and resets all infection-related data.

- **`playerWillDie`**:
  - Marks the player for death after failing the saving throw.

- **`CheckForInfection`**:
  - Monitors the player's infection status and triggers saving throws when appropriate.

- **`PrintStatus`**:
  - Debug function to print the current infection status, saving throw bonuses, and DC.

---

## Future Plans

- Add support for debuff traits (e.g., `ThinSkinned`, `ProneToIllness`).
- After saving a bite infection, character can become re-infected if body and clothes are dirty/bloody and has dirty bandages until wounds are healed

---

## Credits

- **Author**: Levantine
- **Website**: https://levantine.io/

- **Game**: Project Zomboid

- **Mods Referenced**
    - [B41/B42] Mini Health Panel: https://steamcommunity.com/sharedfiles/filedetails/?id=2866258937
    - Antibodies (v1.92) [B41 + B42]: https://steamcommunity.com/sharedfiles/filedetails/?id=2392676812
    - Infection Cancellation with Options [B42,B41]: https://steamcommunity.com/sharedfiles/filedetails/?id=2989529177


---
