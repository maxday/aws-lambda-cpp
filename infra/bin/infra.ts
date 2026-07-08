#!/usr/bin/env node
import * as cdk from "aws-cdk-lib";
import { CodeBuildRunnersStack } from "../lib/codebuild-runners-stack";

const app = new cdk.App();
new CodeBuildRunnersStack(app, "AwsLambdaCppCodeBuildRunners", {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: "eu-west-1",
  },
  synthesizer: new cdk.CliCredentialsStackSynthesizer(),
});
