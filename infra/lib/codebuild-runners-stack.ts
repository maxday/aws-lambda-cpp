import * as cdk from "aws-cdk-lib";
import * as codebuild from "aws-cdk-lib/aws-codebuild";
import * as iam from "aws-cdk-lib/aws-iam";
import * as ssm from "aws-cdk-lib/aws-ssm";
import { Construct } from "constructs";

export class CodeBuildRunnersStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const roleArn = process.env.AWS_CODEBUILD_RELEASE_ROLE_ARN;
    if (!roleArn) {
      throw new Error("AWS_CODEBUILD_RELEASE_ROLE_ARN environment variable is required");
    }

    const connectionArn = ssm.StringParameter.valueForStringParameter(
      this,
      "/github/connection-arn"
    );

    const sourceCredential = new codebuild.CfnSourceCredential(
      this,
      "GitHubSourceCredential",
      {
        authType: "CODECONNECTIONS",
        serverType: "GITHUB",
        token: connectionArn,
      }
    );

    const codeBuildRole = iam.Role.fromRoleArn(
      this,
      "ImportedCodeBuildRole",
      roleArn
    );

    const runners = [
      {
        name: "aws-lambda-cpp-test-trigger-x86",
        image: "aws/codebuild/amazonlinux-x86_64-standard:6.0",
        environmentType: "LINUX_CONTAINER",
      },
      {
        name: "aws-lambda-cpp-test-trigger-arm64",
        image: "aws/codebuild/amazonlinux-aarch64-standard:3.0",
        environmentType: "ARM_CONTAINER",
      },
    ];

    for (const runner of runners) {
      const project = new codebuild.Project(this, runner.name, {
        projectName: runner.name,
        source: codebuild.Source.gitHub({
          owner: "maxday",
          repo: "aws-lambda-cpp",
          cloneDepth: 1,
          webhook: true,
          webhookFilters: [
            codebuild.FilterGroup.inEventOf(
              codebuild.EventAction.WORKFLOW_JOB_QUEUED
            ),
          ],
        }),
        environment: {
          buildImage:
            runner.environmentType === "ARM_CONTAINER"
              ? codebuild.LinuxArmBuildImage.fromCodeBuildImageId(runner.image)
              : codebuild.LinuxBuildImage.fromCodeBuildImageId(runner.image),
          computeType: codebuild.ComputeType.MEDIUM,
        },
        role: codeBuildRole,
        timeout: cdk.Duration.minutes(60),
        queuedTimeout: cdk.Duration.minutes(480),
      });
      project.node.addDependency(sourceCredential);
    }
  }
}
