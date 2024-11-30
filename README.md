# Project Setup Guide

## Overview
This project is built using [streamlit](https://streamlit.io/) and [Amazon Bedrock](https://aws.amazon.com/bedrock/). It is a simple chat bot that uses Amazon Bedrock to generate responses to user queries from a knowledge base of documents.

## Prerequisites
- Python 3.8 or higher
- pip (Python package manager)
- (Optional) Terraform 1.10.5 or higher - only needed if you want to deploy your own infrastructure
- AWS CLI configured with appropriate credentials

## Installation Steps

1. Clone the repository and set up a virtual environment:
   ```bash
   python -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

2. Set up your AWS credentials and region in the environment variables. You can do this by creating a `.streamlit/secrets.toml` file with the following content:
   ```toml
   AWS_REGION = "us-east-1"
   AWS_ACCESS_KEY_ID = "YOUR_ACCESS_KEY_ID"
   AWS_SECRET_ACCESS_KEY = "YOUR_SECRET_ACCESS_KEY"
   KNOWLEDGE_BASE_ID = "YOUR_KNOWLEDGE_BASE_ID"
   ```

   You can get your AWS credentials from the [AWS Management Console](https://us-east-1.console.aws.amazon.com/console/home?region=us-east-1#/settings/details).

   For Production, set the `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION` and `KNOWLEDGE_BASE_ID` in the streamlit secrets dashboard if deployed to streamlit cloud else set them in the environment variables of whichever environment you are deploying to.

3. (Optional) Deploy your own infrastructure:
   If you want to set up your own AWS infrastructure instead of using existing resources, you can use the provided Terraform configuration.

   First, create a `terraform.tfvars` file in the `.infra` directory with the following variables:
   ```bash
   kb_oss_collection_name = "your-kb-name"    # Required: Name for the knowledge base
   index_name = "your-index-name"          # Required: Name for the OpenSearch index
   s3_bucket_name = "your-s3-bucket-name" # Required: Name for your S3 bucket with the documents for the Knowledge Base
   ```

   Then run:
   ```bash
   cd .infra
   terraform init
   terraform plan
   terraform apply
   ```

   This will create:
   - An Amazon OpenSearch Serverless collection
   - A Bedrock Knowledge Base
   - Required IAM roles and policies
   - An S3 data source for the Knowledge Base

4. Run the Streamlit app:
   ```bash
   streamlit run app.py
   ```

## Usage
- The app will open in your default browser. You can interact with the chat bot by entering messages in the chat interface.
- The chat bot will use Amazon Bedrock to generate responses based on the knowledge base.

## Infrastructure (Optional)
The project includes Terraform configuration to manage the AWS infrastructure. If you choose to deploy your own infrastructure, the main components include:
- Amazon OpenSearch Serverless for vector storage
- Amazon Bedrock Knowledge Base for document processing
- IAM roles and policies for secure access
- S3 bucket for document storage

The infrastructure code is located in the `.infra` directory. See the [infrastructure documentation](.infra/README.md) for more details about the resources created. Note that you can also use existing AWS resources by simply configuring the appropriate credentials and knowledge base ID in your secrets file.
