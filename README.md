# AWS Serverless Image Analyzer

This project deploys a complete, secure, full-stack serverless application on AWS using Terraform. It allows authenticated users to upload images, which are then automatically analyzed by Amazon Rekognition to detect labels. Users can then query for the analysis results via a secure API.

This repository is the result of a hands-on learning lab, demonstrating a real-world, event-driven architecture with a secure frontend and backend.

## Architecture Flow

The application consists of two main, decoupled workflows:

**1. The "Writer" Workflow (Asynchronous, Event-Driven):**
*   An authenticated user uploads a file from the web frontend directly to a private **S3 Upload Bucket** using a pre-signed POST URL.
*   The `s3:ObjectCreated` event triggers a **Lambda function (`ImageProcessor`)**.
*   The Lambda function calls **Amazon Rekognition** to detect labels in the uploaded image.
*   The results are stored in a **DynamoDB table** for caching and future lookups.
*   A notification is sent to an **SNS topic** with the analysis summary.

**2. The "Reader" Workflow (Synchronous, Request-Driven):**
*   The user requests results for a specific image from the web frontend.
*   The request goes to a **CloudFront distribution**, which serves the static website.
*   The JavaScript makes a `GET` request to an **API Gateway** endpoint.
*   The API Gateway uses a **Cognito Authorizer** to validate the user's JWT token.
*   If authorized, the API Gateway uses a direct **AWS Service Integration** to query the **DynamoDB table** for the results.
*   The results are returned to the user's browser.

## Features

*   **Infrastructure as Code:** The entire infrastructure is defined and managed with Terraform.
*   **Secure Authentication:** User sign-up and sign-in are handled by **Amazon Cognito**.
*   **Secure API:** The API Gateway is protected with a Cognito Authorizer, requiring all requests to be authenticated.
*   **Secure Frontend:** The CloudFront distribution is protected by **AWS WAF**, which restricts access to a specific country (e.g., Israel).
*   **Secure Uploads:** Uses S3 Pre-signed POSTs to allow users to upload files directly to a private S3 bucket without exposing any credentials.
*   **Cost-Effective:** Fully serverless architecture (Lambda, DynamoDB On-Demand, S3, API Gateway) means you only pay for what you use.
*   **Automated Processing:** S3 event triggers and Lambda functions create a fully automated image analysis pipeline.

## Prerequisites

*   An AWS Account
*   Terraform CLI installed
*   AWS CLI installed and configured with your credentials

## Deployment

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/cosmin1230/aws-serverless-image-analyzer.git
    cd aws-serverless-image-analyzer/terraform
    ```

2.  **Create your variables file:**
    Copy the example file and fill in your email address.
    ```bash
    cp terraform.tfvars.example terraform.tfvars
    # Now edit terraform.tfvars with your details
    ```

3.  **Initialize Terraform:**
    This will download the necessary provider plugins.
    ```bash
    terraform init
    ```

4.  **Deploy the infrastructure:**
    Review the plan and type `yes` to approve. This will create all the AWS resources.
    ```bash
    terraform apply -var-file="terraform.tfvars"
    ```

5.  **Confirm SNS Subscription:** After the `apply` is complete, check your email (the one you put in `terraform.tfvars`) and click the "Confirm subscription" link from AWS.

## Usage

1.  After the `terraform apply` is complete, find the `cloudfront_url` in the Terraform outputs.
2.  Open this URL in your browser.
3.  You will be redirected to the login page. Sign up for a new account.
4.  Verify your email with the code Cognito sends you.
5.  Sign in with your new credentials.
6.  You can now upload images and get their analysis results.

## Destruction

To avoid ongoing costs, you can destroy all the created resources with a single command.
```bash
terraform destroy -var-file="terraform.tfvars"
```