# Cloud Reader (Text-to-Speech)

## Overview
This project builds a multiplatform iOS/macOS application that can:
1. Read a linked webpage
2. Upload a document - txt, pdf, epub
3. Read the uploaded documents using text to speech. The supported TTS synthesizers are:
  a) Local Apple TTS
  b) Amazon Polly Cloud TTS
  c) Google Cloud TTS
  d) Microsoft Azure TTS
  
For the Cloud TTS, user needs to use their own AWS/Google Cloud/Azure accounts. The setup below will guide you through what resources to deploy. All of these cloud services are a pay-as-you-go model, so you'll only pay for what you actually read instead of a subscription that you pay to some app developer. See below for what the pricing looks like for each cloud service. You might also qualify for free tier options, new account credits and free monthly quotas.

1. Amazon Polly - https://aws.amazon.com/polly/pricing/
2. Google Cloud - https://cloud.google.com/text-to-speech/pricing
3. Microsoft Azure - https://azure.microsoft.com/en-us/pricing/details/cognitive-services/speech-services/

## Setup App
Just build the project in Xcode, sign it for local development and install it in your devices.

## Setup Amazon Polly

1. Create an AWS account or use an existing one.
2. Open the AWS Console -> select any region you like (in the region selector on top-right)
3. Search for CloudFormation in the Console search -> Create Stack -> Upload a template -> Use the template in the [Dist/AmazonPollyCFN.yaml](Dist/AmazonPollyCFN.yaml)
4. Wait for stack to complete creation and then note down the value of `identityPoolId` in the Outputs tab of the stack
5. Provide the identityPoolId in the environment variables of Xcode (Product -> Scheme -> Edit Scheme -> Value for COGNITO_IDENTITY_POOL_ID)
