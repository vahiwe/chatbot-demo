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

bedrock_agent_runtime_client = session.client('bedrock-agent-runtime')

# Streamed response generator
def response_generator(prompt):
    knowledge_base_id = '4ZCMRGRQDU'
    modelId = 'anthropic.claude-3-sonnet-20240229-v1:0'
    modelArn = f'arn:aws:bedrock:us-east-1::foundation-model/{modelId}'
    native_request = f"""\n\nHuman:
    Please answer [question] appropriately.
    [question]
    {prompt}
    Assistant:
    """

    response = bedrock_agent_runtime_client.retrieve_and_generate(
        input={
            'text': native_request,
        },
        retrieveAndGenerateConfiguration={
            'type': 'KNOWLEDGE_BASE',
            'knowledgeBaseConfiguration': {
                'knowledgeBaseId': knowledge_base_id,
                'modelArn': modelArn,
            }
        }
    )
    response_text = response['output']['text']
    for word in response_text.split():
        yield word + " "
        time.sleep(0.05)


st.title("Chat with me about the AWS EC2 Service")
st.caption("This chatbot is powered by Claude 3 Sonnet as the foundation model and an AWS Bedrock knowledge base of AWS EC2 documentation.")

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