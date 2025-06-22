# Spaceship Deck

A set of tools that play the [Space Traders game](https://spacetraders.io), all
programmed in Dart.

## Architecture

The component that actively _plays_ the game by sending API calls to the Space
Traders server is the [**Main Computer**](/packages/main_computer/README.md).
It is a Dart CLI application.

The **Deck Controller** is a Flutter application that allows a human unit to
control the Main Computer using a GUI.

More components will be created to store metrics and probably more in the
future.

## Development installation

### Requirements

Having Java installed.

Meeting the [prerequisites](https://grpc.io/docs/languages/dart/quickstart/#prerequisites) for gRPC.

### Setup

1. Clone the repository
1. `dart pub get` in the root directory
1. `dart run build_runner build` in `/packages/main_computer` to autogenerate the SpaceTraders API code
1. `./tools/autogen.sh` in `/packages/commons` to autogenerate the Protobuf code
