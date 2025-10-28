import { Theme, ThemeName } from "./types";
import { defaultTheme } from "./default";
import { darkPurpleTheme } from "./dark-purple";
import { cyberBlueTheme } from "./cyber-blue";
import { forestGreenTheme } from "./forest-green";
import { sunsetOrangeTheme } from "./sunset-orange";

export * from "./types";

export const themes: Record<ThemeName, Theme> = {
  default: defaultTheme,
  "dark-purple": darkPurpleTheme,
  "cyber-blue": cyberBlueTheme,
  "forest-green": forestGreenTheme,
  "sunset-orange": sunsetOrangeTheme,
};

export const themeNames: ThemeName[] = ["default", "dark-purple", "cyber-blue", "forest-green", "sunset-orange"];

