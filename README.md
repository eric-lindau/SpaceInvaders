![](space_invaders.png)
*A verilog recreation of the classic arcade game Space Invaders. This game was run on a Cyclone V FPGA Board and has VGA output.*

## Gameplay
As in the original Space Invaders game, players can move the cannon and shoot at aliens (using buttons on the FPGA board). The player must
shoot all aliens before they reach the bottom to win the game, at which point the game will stop and can be reset. The aliens will move sideways and downwards on a set clock until they reach the bottom, at which point the player loses the game, and a game over screen is shown. The player's score is shown in the top right, which increases every time an alien is killed.

Included in this repository is a video called demo_video which shows gameplay for the game.

## Technical
This project was built using Quartus Lite 17.0 and uploaded onto a Cyclone V FPGA board. The game outputs to a VGA, and takes input directly from the board.

## Authors
- **[Eric Lindau](https://github.com/eric-lindau)**
- **[Thomas MacDonald](https://github.com/thomasdmacdonald)**

This game was created as a final project for the course CSC258 at the University of Toronto.

*Note: The files black.mif, DE1_SoC.qsf, and all files inside of the folder vga_adapter were provided as is by
the University of Toronto Department of Computer Science. All other files were written by the authors.*
