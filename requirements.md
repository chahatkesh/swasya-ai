**Project Mission:** To build an AI co-pilot for India's Primary Healthcare Centers (PHCs) that eliminates the data-entry bottleneck, bridges language barriers, and provides real-time, life-saving patient history to doctors.

**Target Personas:**

- **Nurse Rekha (Data Input):** Uses the mobile app to register patients, scan old documents, and record conversations.
    
- **Dr. Priya (Data Consumer):** Uses the web dashboard to see a patient's entire history and live-updating notes _before_ they enter the room.
    

**Target Hackathon Tracks:**

- **Base44:** Challenge 2: Healthcare Technology Innovation1.
    
- **AWS:** Remarkable Integration of AWS.
    
- **Qyrus:** Innovative Testing.
    
- **Gemini:** Deep Integration of AI.
    

---

### **System Architecture (The "How-It-Works" Flow)**

This is the end-to-end "WOW" loop.

1. **Frontend (Input):** Nurse Rekha's **Flutter App** uploads an audio file and an image file directly to two different **Amazon S3** buckets.
    
2. **Trigger (AWS):** These S3 uploads create an "event" that automatically triggers two separate **AWS Lambda** functions (serverless scripts).
    
3. **Process (AWS + Gemini):**
    
    - **Lambda 1 (Scribe):** Sends the audio file to **Amazon Transcribe** to get text. It then sends that text to the **Gemini API** to be structured into a SOAP note.
        
    - **Lambda 2 (Digitizer):** Sends the image file to **Amazon Textract** to extract handwritten text. It then sends that text to the **Gemini API** to be structured into a medication timeline.
        
4. **Store (AWS):** Both Lambda functions write their structured JSON output to **Amazon DynamoDB** (a super-fast NoSQL database).
    
5. **Push (AWS Real-Time):** **DynamoDB Streams** detects the new data, which triggers a _third_ **Lambda function (PushTask)**. This Lambda's _only_ job is to push the new data to an **AWS IoT Core (MQTT)** topic.
    
6. **Frontend (Output):** Dr. Priya's **Web Dashboard** is subscribed to the AWS IoT Core topic. The new data appears on her screen _instantly_, creating the "Live Typewriter" effect.
    

---

### **Component 1: Nurse Mobile App (Flutter)**

**Goal:** Fast, simple, and reliable data capture.

#### **F1.1: Patient Registration (Must-Have)**

- **What it does:** A simple form to register a new patient or find an existing one.
    
- **`How-to` (Technical Flow):**
    
    1. **UI:** Create a Flutter screen with fields for "Full Name" and "Phone Number".
        
    2. **Backend:** On "Register," your Flutter app calls your backend API (e.g., an AWS API Gateway endpoint triggering a Lambda).
        
    3. This Lambda function creates a new item in your `Patients` DynamoDB table and returns a unique `patient_id`.
        
    4. Your Flutter app _must_ store this `patient_id` in its state to use for all subsequent uploads for this patient.
        

#### **F1.2: AI Scribe (The "Demo" Feature 1)**

- **What it does:** Records the nurse-patient conversation and uploads it for processing.
    
- **User Story:** "As Nurse Rekha, I want to press one button to record my conversation with Mr. Kumar in Hindi, and have it be automatically understood."
    
- **`How-to` (Technical Flow):**
    
    1. **UI:** Use the `flutter_sound` package. Show a big "Start Recording" button. While recording, show a pulsing animation.
        
    2. **On Stop:** The app will have a local audio file (e.g., `audio.mp4`).
        
    3. **Upload:** Use the `aws-sdk-flutter` (or a pre-signed S3 URL from your backend) to upload this file _directly_ to your `s3://audio-uploads` bucket.
        
    4. **CRITICAL:** The file _must_ be named using the patient's ID, e.g., `patient_id_12345/scribe_1.mp4`. This is how your backend knows who the file belongs to.
        

#### **F1.3: AI Digitizer (The "Demo" Feature 2)**

- **What it does:** Scans old, crumpled paper prescriptions and uploads them.
    
- **User Story:** "As Nurse Rekha, I want to take one photo of Mr. Kumar's bag of papers so the doctor can finally read them."
    
- **`How-to` (Technical Flow):**
    
    1. **UI:** Use the `camera` package. Open a full-screen camera view.
        
    2. **On Capture:** Show a "Confirm" screen with the captured image.
        
    3. **Upload:** On "Confirm," upload the `.jpg` image _directly_ to your `s3://image-uploads` bucket.
        
    4. **CRITICAL:** This file _must_ also be named with the patient's ID, e.g., `patient_id_12345/doc_1.jpg`.
        

---

### **Component 2: Backend (AWS Serverless + Gemini)**

**Goal:** Run the entire AI pipeline in real-time with zero servers to manage.

#### **F2.1: Scribe Pipeline (Lambda + Transcribe + Gemini)**

- **Trigger:** New file appears in `s3://audio-uploads`.
    
- **`How-to` (Lambda Function 1 - `ScribeTask`):**
    
    1. **Event:** The Lambda function is triggered by S3; it receives the `bucket` and `key` (file name).
        
    2. **Transcribe:** Use the AWS SDK (e.g., `boto3` for Python) to call **Amazon Transcribe**.
        
        - `transcribe.start_transcription_job(...)`
            
        - Specify `LanguageCode='hi-IN'` (Hindi) or `en-IN` (Indian English).
            
    3. **Get Text:** On job completion, get the raw transcribed text.
        
    4. **Gemini (The Magic):** Call the **Gemini API** with this prompt:
        
        > "You are an expert medical scribe. Convert this messy patient-nurse conversation into a clean, structured JSON SOAP note (Subjective, Objective, Assessment, Plan). Conversation: [transcribed text]"
        
    5. **Store:** Parse the JSON response from Gemini and save it to your `PatientNotes` DynamoDB table, using the `patient_id` (from the filename) as the primary key.
        

#### **F2.2: Digitizer Pipeline (Lambda + Textract + Gemini)**

- **Trigger:** New file appears in `s3://image-uploads`.
    
- **`How-to` (Lambda Function 2 - `DigitizeTask`):**
    
    1. **Event:** Receives the `bucket` and `key` (file name).
        
    2. **Textract:** Use the AWS SDK to call **Amazon Textract**.
        
        - `textract.analyze_document(..., FeatureTypes=['HANDWRITING', 'FORMS'])`. This is your "WOW" feature for reading paper.
            
    3. **Get Text:** Textract will return a JSON of all extracted text, forms, and handwritten notes. Concatenate this into a single text block.
        
    4. **Gemini (The Magic):** Call the **Gemini API** with this prompt:
        
        > "You are a medical analyst. Extract all medications, diagnoses, and dates from this unstructured OCR data. Return a clean JSON list. Data: [Textract output]"
        
    5. **Store:** Save this new JSON list to your `PatientHistory` DynamoDB table.
        

#### **F2.3: Real-Time RAG & Push (The "Winning" Features)**

- **`How-to` (Lambda Function 3 - `RAG_Task`):**
    
    - **What:** This is the "RAG Timeline" generation.
        
    - **Trigger:** This function is triggered by **API Gateway** when Dr. Priya's dashboard loads.
        
    - **Flow:**
        
        1. It receives the `patient_id` from the API call.
            
        2. **Retrieve:** It queries the `PatientHistory` table in DynamoDB for _all_ items for that `patient_id`.
            
        3. **Augment:** It builds a large prompt for **Gemini API**: "Summarize this patient's entire medical history into a clean timeline: [JSON list of all 10 reports]."
            
        4. **Generate:** It returns the clean, bulleted timeline from Gemini.
            
- **`How-to` (Lambda Function 4 - `PushTask`):**
    
    - **What:** This is the "Live Typewriter" engine.
        
    - **Trigger:** **DynamoDB Streams** on the `PatientNotes` table.
        
    - **Flow:**
        
        1. As soon as the `ScribeTask` saves a _new_ SOAP note, this Lambda instantly triggers.
            
        2. It takes the new JSON data from the stream.
            
        3. It uses the AWS SDK to publish this data to an **AWS IoT Core (MQTT)** topic, e.g., `patient/patient_id_12345/updates`.
            

---

### **Component 3: Doctor Web Dashboard (React)**

**Goal:** Display all patient data in a "live" interface.

#### **F3.1: Patient View (Must-Have)**

- **What it does:** The main screen Dr. Priya uses.
    
- **`How-to` (Technical Flow):**
    
    1. **UI:** A 2-column layout. Left column is a list of patients (from your `Patients` table). Right column is the selected patient's details.
        
    2. **On Load (RAG):** When Dr. Priya clicks a patient, the app _first_ calls the `RAG_Task` API endpoint. The returned timeline is displayed at the _top_ of the right column.
        
    3. **On Load (Live):** The app _also_ uses the **AWS Amplify** library to subscribe to the IoT Core (MQTT) topic: `patient/patient_id_12345/updates`.
        
    4. **The "Live Typewriter" Effect:**
        
        - You'll have a `useEffect` hook in React listening for new MQTT messages.
            
        - When a new SOAP note arrives, add it to a state array (`notes`).
            
        - Render this array. To create the "typewriter" effect, use a library like `react-type-animation` on the _newest_ item in the array. This will make it look like it's being typed in real-time.
            

---

### **Component 4: Sponsor Requirements (The "Win" Plan)**

R1: Base44 (The "Hub") 2

- **What:** Your project's front-door.
    
- **`How-to`:**
    
    1. Use a Base44 template to build a beautiful landing page in < 30 minutes.
        
    2. **Content:** Tell the "Dr. Priya & Mr. Kumar" story.
        
    3. **Required:** Must include a way to "test the idea"3. Add a "Request Pilot Access" button that links to a simple Google Form.
        
    4. **Required:** This page is your submission's "live link"4444. Add two big buttons: "View Doctor Dashboard Demo" (links to your deployed React app) and "Download Nurse App (APK)".
        
    5. Submission Text5: "Base44 was our mission control. It allowed us to build a professional, public-facing landing page and feedback form in minutes, letting our team focus 100% on the complex, serverless AI pipeline."
        

#### **R2: AWS (The "Architecture")**

- **What:** "Remarkable Integration."
    
- **`How-to`:** Your entire architecture is the "remarkable" part. In your demo, you _must_ show a slide with the full data flow diagram (S3 -> Lambda -> Transcribe/Textract -> Gemini -> DynamoDB -> Streams -> IoT Core -> React). You are using 7 different AWS services in a modern, event-driven, serverless pattern. This is an advanced, prize-winning architecture.
    

#### **R3: Qyrus (The "Crazy" Test)**

- **What:** Prove your AI pipeline works.
    
- **`How-to` (Using `qapi`):**
    
    1. Create a Qyrus test script.
        
    2. **Test 1 (AI Scribe):** The script makes a direct API call to your backend, simulating the S3 upload of a test _audio_ file (`hindi_fever.mp3`).
        
    3. **Test 2 (AI Digitizer):** The script makes a second API call, simulating the upload of a test _image_ (`blurry_paracetamol.jpg`).
        
    4. **The "WOW" Assertion:** The script then polls a test-only "get_data" endpoint. It _asserts_ that the JSON data in your database _actually contains_ `diagnosis: "fever"` and `medication: "Paracetamol"`.
        
    
    - **Why it Wins:** You are doing end-to-end AI-accuracy testing, not just "is the server on?" testing.
        

#### **R4: Gemini (The "Brain")**

- **What:** The core intelligence.
    
- **`How-to`:** Emphasize that Gemini is _not_ just a chatbot. It's the cognitive engine performing three distinct, critical tasks:
    
    1. **Scribe -> Structure:** Converts a messy conversation into a medical SOAP note.
        
    2. **OCR -> Structure:** Converts messy paper text into a clean medication list.
        
    3. **History -> Synthesis (RAG):** Converts 10 scattered reports into one actionable timeline.
        