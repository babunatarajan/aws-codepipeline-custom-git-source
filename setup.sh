#!/bin/bash

echo "The script will generate a SSH Private/Public key for AWS Secrets Manager and creates Secret for CodePipeLine"
echo "CloudFormation Stack creates a S3 bucket and custom Git repo option under CodePipeLine Source."
echo "Make sure EC2 instance from you are running the script has IAM Role attached with Administrator privilege... or use the correct AWS Login profile."
echo "Hit CTRL+C to stop the execution, or wait for 10 seconds..."
sleep 10

apt -y install zip
apt -y install python3-pip
pip3 install awscli

REGION="ap-south-1"

ssh-keygen -t rsa -b 4096 -C "user@example.com" -f codepipeline_git_rsa

export SecretsManagerArn=$(aws secretsmanager create-secret --name codepipeline_git \
--secret-string file://codepipeline_git_rsa --query ARN --output text --region ${REGION})
echo $SecretsManagerArn
git clone https://github.com/aws-samples/aws-codepipeline-third-party-git-repositories.git /tmp/aws-codepipeline-third-party-git-repositories
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --region ${REGION})
export S3_BUCKET_NAME=codepipeline-git-custom-action-${ACCOUNT_ID}
aws s3 mb s3://${S3_BUCKET_NAME} --region ${REGION}

export ZIP_FILE_NAME="codepipeline_git.zip"
zip -jr ${ZIP_FILE_NAME} /tmp/aws-codepipeline-third-party-git-repositories/lambda/lambda_function.py && aws s3 cp codepipeline_git.zip s3://${S3_BUCKET_NAME}/${ZIP_FILE_NAME}

export vpcId="vpc-xxx"
export subnetId1="subnet-xxx"
export subnetId2="subnet-xxx"
export GIT_SOURCE_STACK_NAME="thirdparty-codepipeline-git-source"
aws cloudformation create-stack \
--region ${REGION} \
--stack-name ${GIT_SOURCE_STACK_NAME} \
--template-body file:///tmp/aws-codepipeline-third-party-git-repositories/cfn/third_party_git_custom_action.yaml \
--parameters ParameterKey=SourceActionVersion,ParameterValue=1 \
ParameterKey=SourceActionProvider,ParameterValue=CustomSourceForGit \
ParameterKey=GitPullLambdaSubnet,ParameterValue=${subnetId1}\\,${subnetId2} \
ParameterKey=GitPullLambdaVpc,ParameterValue=${vpcId} \
ParameterKey=LambdaCodeS3Bucket,ParameterValue=${S3_BUCKET_NAME} \
ParameterKey=LambdaCodeS3Key,ParameterValue=${ZIP_FILE_NAME} \
--capabilities CAPABILITY_IAM
