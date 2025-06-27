import type { Config } from "@jest/types";

const config: Config.InitialOptions = {
  verbose: true,
  transform: {
    "\\.[jt]s$": "babel-jest",
  },
  moduleFileExtensions: ["js", "ts"]
};

export default config;
