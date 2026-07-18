[working-directory("packages/main_computer")]
run-computer:
    ./bin/boot.exe

[working-directory("packages/main_computer")]
build-computer:
    dart compile exe bin/boot.dart
