import printBanner from "@utilities/printBanner";
import chalk from "chalk";
import { readFile, readdir, writeFile } from "fs/promises";
import Handlebars from "handlebars";
import cmd from "cmd-promise";
import spin from "@utilities/spin";
import path from "path";
import { FlagsType } from "src/cli";
import jsyaml from "js-yaml";
import { readFileSync } from "fs";

export default async (flags: FlagsType) => {
  console.log(`Inputs `, flags);
  const { name, schema, env } = flags;

  if (!name) {
    console.log(chalk.red(`[project-name] argument not provied `));
    throw new Error(`[project-name] argument not provided `);
  }

  if (!schema) {
    console.log(chalk.red(`[schema] argument not provied `));
    throw new Error(`[schema] argument not provided `);
  }

  if (!env) {
    console.log(chalk.red(`[env] argument not provied `));
    throw new Error(`[env] argument not provided `);
  }

  printBanner();

  const schemasDir = `${path.join(__dirname, "../../", "schemas")}`;
  const folderManifests = (await readdir(path.join(schemasDir, schema))).filter(
    (file) => file !== "skaffold.yaml",
  );
  console.log(`${chalk.bold.magenta(`Processing files`)} - ${folderManifests}`);

  await cmd(`rm -rf ${process.cwd()}/manifests || true`);
  await cmd(`mkdir ${process.cwd()}/manifests`);

  const projectConfig = readProjectConfiguration(flags);
  console.log(
    chalk.magenta.bold(
      `Generated configuration for [${flags.env}] environment and project [${flags.name}] with schema [${flags.schema}]`,
    ),
  );
  console.log(projectConfig);

  await generateCompiledManifests(
    path.join(schemasDir, schema),
    folderManifests,
    flags,
    projectConfig,
  );
  await generateMainSkaffoldFile(path.join(schemasDir, schema), "skaffold.yaml", projectConfig);

  spin(true);
  console.log(chalk.green.bold(`\n🚀 Manifest files processed succesfully`));
};

const readProjectConfiguration = (flags: FlagsType) => {
  const configsDir = `${path.join(__dirname, "../../", "configs")}`;

  const defaultYamlContent = jsyaml.load(
    readFileSync(path.join(configsDir, `default.yml`), "utf-8"),
  );

  const yamlContent = jsyaml.load(
    readFileSync(path.join(configsDir, `${flags.name}.yml`), "utf-8"),
  );

  let mergedConfiguration = Object.assign(
    {},
    defaultYamlContent["defaults"],
    defaultYamlContent[flags.env],
    {
      env_variables: Object.assign(
        {},
        defaultYamlContent["defaults"]?.env_variables,
        defaultYamlContent[flags.env]?.env_variables,
      ),
    },
  );

  mergedConfiguration = Object.assign(
    mergedConfiguration,
    yamlContent["defaults"],
    yamlContent[flags.env],
    {
      env_variables: Object.assign(
        yamlContent["defaults"]?.env_variables,
        yamlContent[flags.env]?.env_variables,
      ),
    },
  );

  mergedConfiguration = Object.assign(mergedConfiguration, {
    BRANCH_NAME: process.env.BRANCH_NAME,
    REPO_NAME: process.env.REPO_NAME,
    COMMIT_SHA: process.env.COMMIT_SHA,
    SHORT_SHA: process.env.SHORT_SHA,
    APP_IMAGE: process.env.APP_IMAGE,
  });

  return mergedConfiguration;
};

const generateCompiledManifests = async (
  schemasDir: string,
  folderManifests: string[],
  flags: FlagsType,
  projectConfig: Record<string, unknown>,
) => {
  for (const file of folderManifests) {
    spin(chalk.green(`Processing file ${chalk.bold.yellow(file)}`));

    await processManifest(
      schemasDir,
      file,
      `${process.cwd()}/manifests/k8s-${flags.env}-${file}`,
      projectConfig,
    );
  }
};

const generateMainSkaffoldFile = async (
  schemasDir: string,
  fileName: string,
  projectConfig: Record<string, unknown>,
) => {
  spin(chalk.green(`Processing file ${chalk.bold.yellow(fileName)}`));

  await processManifest(schemasDir, fileName, `${process.cwd()}/${fileName}`, projectConfig);
};

const processManifest = async (
  schemasPath: string,
  fileName: string,
  destFileName: string,
  projectConfig: Record<string, unknown>,
) => {
  const content = (
    await readFile(path.join(schemasPath, fileName)).catch((err) => {
      console.log(`Could not read file ${fileName} - ${err.message}`);
      return "";
    })
  )
    .toString("utf-8")
    .replace("---", "");

  const manifestTemplate = Handlebars.compile(content, {noEscape: false});
  const compiledTemplate = manifestTemplate(projectConfig);
  await writeFile(destFileName, `---\n${compiledTemplate}`, "utf-8");
};
