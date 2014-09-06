part of Dark;

class Game {
  static const String NAME = "DARK";
  static const String VERSION = "0.1";

  static bool ORIGINAL_RESOLUTION = true; // Original doom was 320x200 pixels
  static bool ORIGINAL_SCREEN_ASPECT_RATIO = false; // Original doom was 4:3.
  static bool ORIGINAL_PIXEL_ASPECT_RATIO = true; // Original doom used slightly vertically stretched pixels (320x200 pixels in 4:3)
  
  static double MIN_ASPECT_RATIO = 4/3; // Letterbox if aspect ratio is lower than this
  static double MAX_ASPECT_RATIO = 2/1; // Pillarbox if aspect ratio is higher than this
}