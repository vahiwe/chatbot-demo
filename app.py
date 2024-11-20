import json 
import boto3
import time
import streamlit as st

AWS_REGION = st.secrets["AWS_REGION"]
AWS_ACCESS_KEY_ID = st.secrets["AWS_ACCESS_KEY_ID"]
AWS_SECRET_ACCESS_KEY = st.secrets["AWS_SECRET_ACCESS_KEY"]

# Initialize AWS Bedrock client
session = boto3.Session(
    aws_access_key_id=AWS_ACCESS_KEY_ID,
    aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
    region_name=AWS_REGION,
)

bedrock_client = session.client("bedrock-runtime")

# Streamed response generator
def response_generator(prompt):
    prompt_data = f"""Command: {prompt}
    Response:
    """
    body = json.dumps(
        {"inputText": prompt_data, 
        "textGenerationConfig" : {"topP":0.95, "temperature":0.2}}
    )
    modelId = "amazon.titan-tg1-large" 
    accept = "application/json"
    contentType = "application/json"

    titan_response = bedrock_client.invoke_model(
        body=body, 
        modelId=modelId, 
        accept=accept, 
        contentType=contentType
    )
    response = json.loads(titan_response.get("body").read())
    response_text = response.get("results")[0].get("outputText")
    for word in response_text.split():
        yield word + " "
        time.sleep(0.05)


st.title("Chat with Bedrock")

# Initialize chat history
if "messages" not in st.session_state:
    st.session_state.messages = []

# Display chat messages from history on app rerun
for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])

# Accept user input
if prompt := st.chat_input("What is up?"):
    # Add user message to chat history
    st.session_state.messages.append({"role": "user", "content": prompt})
    # Display user message in chat message container
    with st.chat_message("user"):
        st.markdown(prompt)

    # Display assistant response in chat message container
    with st.chat_message("assistant"):
        response = st.write_stream(response_generator(prompt))
    # Add assistant response to chat history
    st.session_state.messages.append({"role": "assistant", "content": response})