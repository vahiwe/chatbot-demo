# Project Setup Guide

## Overview
This project is built using [streamlit](https://streamlit.io/) and [Amazon Bedrock](https://aws.amazon.com/bedrock/). It is a simple chat bot that uses Amazon Bedrock to generate responses to user queries from a knowledge base of documents.

## Prerequisites
- Python 3.8 or higher
- pip (Python package manager)

## Installation Steps

1. Clone the repository and set up a virtual environment:
   ```bash
   python -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

2. Set up your AWS credentials and region in the environment variables.

3. Run the Streamlit app:
   ```bash
   streamlit run app.py
   ```

## Usage
- The app will open in your default browser. You can interact with the chat bot by entering messages in the chat interface.
- The chat bot will use Amazon Bedrock to generate responses based on the knowledge base.

