// Openapi Generator last run: : 2025-06-18T16:57:01.459872
import 'package:openapi_generator_annotations/openapi_generator_annotations.dart';

@Openapi(
  inputSpec: RemoteSpec(path: "https://spacetraders.io/SpaceTraders.json"),
  generatorName: Generator.dart,
  outputDirectory: "space_traders_api",
  additionalProperties: AdditionalProperties(
    pubName: "space_traders",
  ),
  skipIfSpecIsUnchanged: true
)
class SpaceTradersApiGenerator {
}