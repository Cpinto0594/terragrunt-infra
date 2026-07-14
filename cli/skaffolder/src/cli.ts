import "module-alias/register";
import chalk from "chalk";
import meow, { AnyFlags } from "meow";
import { COMMAND_PREFIX } from "./constants/constants";
import init from "./init";
import handlebars_helpers from "handlebars-helpers";
import Handlebars from "handlebars";
handlebars_helpers({ hanlebars: Handlebars });
require("dotenv").config();

const flags = {
  env: {
    type: `string`,
  },
  name: {
    type: `string`,
  },
  schema: {
    type: `string`,
  },
} as const;

type FlagsTypeKeys = keyof typeof flags;

export type FlagsType = {
  [k in FlagsTypeKeys]: string;
};

const cli = meow(
  `
  Usage:
  ${chalk.green(
    `$ ${chalk.bold(
      `${COMMAND_PREFIX} init --name ${chalk.italic(`[project-name]`)} --env ${chalk.italic(
        `[env]`,
      )} --schema ${chalk.italic(`[schema]`)} `,
    )}`,
  )}
  `,
  {
    flags,
  },
);

(async () => {
  const { input: inputs, flags, showHelp } = cli;
  const [action] = inputs;

  switch (action) {
    case `init`:
      return init(flags);
    default:
      console.log(
        `${chalk.bold.red(`ERROR: `)} (${COMMAND_PREFIX}) Invalid choice: '${inputs[0] ?? ""}'.`,
      );
      return showHelp();
  }
})();
