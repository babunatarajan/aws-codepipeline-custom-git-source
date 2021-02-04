# aws-codepipeline-custom-git-source

OS: Ubuntu 20.04.  

The script will generate a SSH Private/Public key for AWS Secrets Manager and creates Secret for CodePipeLine.  

CloudFormation Stack creates a S3 bucket and custom Git repo option under CodePipeLine Source.  

Make sure EC2 instance from you are running the script has IAM Role attached with Administrator privilege... or use the correct AWS Login profile.
