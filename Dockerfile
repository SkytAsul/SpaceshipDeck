# Specify the Dart SDK base image version using dart:<version> (ex: dart:2.12)
FROM dart:stable AS build

# Resolve app dependencies.
WORKDIR /app
COPY pubspec.* ./
COPY packages/commons/pubspec.* ./packages/commons/
COPY packages/main_computer/pubspec.* ./packages/main_computer/
COPY packages/main_computer/space_traders_api/pubspec.* ./packages/main_computer/space_traders_api/
RUN dart pub get --directory=./packages/main_computer

# Copy app source code and AOT compile it.
COPY packages/commons ./packages/commons
COPY packages/main_computer ./packages/main_computer
# Ensure packages are still up-to-date if anything has changed
RUN dart pub get --offline --directory=./packages/main_computer
RUN dart compile exe packages/main_computer/bin/boot.dart -o ./packages/main_computer/bin/spaceship_deck

# Build minimal serving image from AOT-compiled `/server` and required system
# libraries and configuration files stored in `/runtime/` from the build stage.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/packages/main_computer/bin/spaceship_deck /app/

# Start server.
EXPOSE 58471
CMD ["/app/spaceship_deck"]
