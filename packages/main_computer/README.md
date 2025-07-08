# Main Computer
The main computer that manages the spaceship.

## Architecture
- `/bin/boot.dart` is responsible for:
    + loading the kernel (with all its units) via the USB
    + booting up the kernel
    + providing a Console to the administrator
    + shutting down the kernel when the console is exited
- the USB (`/lib/universal_spaceship_bootloader.dart`)
    + sets up the logging system
    + creates a kernel with all the units needed
- the kernel (`/lib/kernel.dart`) manages all of the computer
    - loading/unloading services
    - providing exposed data from the services
    - periodically running the timers

## Services

### Extra-ship Communications
Communicates with the Universe through the SpaceTradersAPI REST endpoints.

Exposes:
- an `ApiClient` instance

### Communication Bus
Receives commands from the rest of the spaceship with gRPC and Protobuf.

### Remote Control
Allows connection via Telnet for remote control. The connection is _unsecure_ and is therefore only reachable on the IPv6 loopback address, port 58471.
