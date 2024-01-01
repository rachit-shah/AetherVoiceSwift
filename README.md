# AetherVoice Cloud Reader (Text-to-Speech)

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

1. Create an AWS account or use an existing one. https://aws.amazon.com/free
2. Open the AWS Console -> select any region you like (in the region selector on top-right) (Some voices are not available in certain regions. I recommend us-east-1 for all voices) [Console Link](https://us-east-1.console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/create)
3. Search for CloudFormation in the Console search -> Create Stack -> Upload a template -> Use the template in the [AetherVoice/Dist/AmazonPollyCFN.yaml](AetherVoice/Dist/AmazonPollyCFN.yaml)
4. Wait for stack to complete creation and then note down the value of `identityPoolId` in the Outputs tab of the stack
5. Provide the identityPoolId in AWS configuration in the Settings of the app. (Note: the identityPoolId acts like a password to access your AWS account's Polly resources. Don't share it with anyone. The value will be securely stored in your keychain upon entering it)

## Setup Google Cloud

### Step 0: Setup GCP account
1. Sign up for GCP or use an existing account: https://cloud.google.com
2. Sign in to your [Google Cloud Console](https://console.cloud.google.com/).
3. Create a new project "AetherVoice" on the top-bar or use an existing project.

### Step 1: Enable Google Cloud Text-to-Speech API
1. Access the [API Library](https://console.cloud.google.com/apis/library/texttospeech.googleapis.com) for the Text-to-Speech API.
2. Select your project and click the "Enable" button.

### Step 2: Generate an API Key and restrict it's usage
1. Visit the [Credentials page](https://console.cloud.google.com/apis/credentials).
2. Click on “Create Credentials” and choose "API key". Your new API key will appear; click "Close" to save it.
3. Click on the name of the new API key to open its settings page.
4. Under "Application restrictions", select "iOS apps" and add the bundle identifier 'com.ract.AetherVoice' (You can change the bundle id in Xcode if you want)
5. Under "API restrictions", select "Restrict key" and choose "Google Cloud Text-to-Speech API" from the dropdown list.
6. Click "Save" to apply the restrictions.

[Source in GCP Docs - Create API Keys](https://cloud.google.com/docs/authentication/api-keys#create)
[Source in GCP Docs - Restrict API key usage in iOS apps](https://cloud.google.com/docs/authentication/api-keys#ios)

### Provide API key in AetherVoice Settings
Provide the generated API key in AWS configuration in the Settings -> GCP Configuration of the AetherVoice app. 

(Note: the API key acts like a password to access your GCP account's Text-to-Speech API. Don't share it with anyone. The value will be securely stored in your keychain upon entering it)
