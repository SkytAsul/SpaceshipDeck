# Spaceship Deck

A set of tools that play the [Space Traders game](https://spacetraders.io), all
programmed in Dart.

## Architecture

The component that actively _plays_ the game by sending API calls to the Space
Traders server is the **Main Computer**. It is a Dart CLI application.

The **Deck Controller** is a Flutter application that allows a human unit to
control the Main Computer using a GUI.

More components will be created to store metrics and probably more in the
future.
