# !pip install openai

import openai
from openai import OpenAI
import time

# Configure the OpenAI client with the vLLM endpoint and token
base_url = "https://gmodel-demo-vllm.apps.cluster-mh5bv.mh5bv.sandbox5379.opentlc.com/v1"
api_key = "token"

# Initialize the OpenAI client
client = OpenAI(
    base_url=base_url,
    api_key=api_key
)

# Define the chat template (adjust based on your model's requirements)
chat_template = "{% for message in messages %}{{ message.role }}: {{ message.content }}{% if not loop.last %}\n\n{% endif %}{% endfor %}"

# Number of inference calls
num_calls = 10
responses = []

# Make 50 inference calls
for i in range(num_calls):
    print(f"\nMaking inference call {i+1}/{num_calls}")
    try:
        response = client.chat.completions.create(
            model="gmodel",
            messages=[
                {
                    "role": "user",
                    "content": "What is AI?"
                }
            ],
            extra_body={
                "chat_template": chat_template
            },
            max_tokens=512,  # Adjust as needed
            temperature=0.7  # Adjust as needed
        )

        # Store the response
        responses.append({
            "call": i + 1,
            "status": "success",
            "response": response.choices[0].message.content
        })
        print(f"Call {i+1} succeeded")

    except openai.APIError as e:
        error_details = e.response.text if hasattr(e, 'response') and e.response is not None else str(e)
        responses.append({
            "call": i + 1,
            "status": "failed",
            "error": str(e),
            "error_details": error_details
        })
        print(f"Call {i+1} failed: {e}")

    # Add a small delay to avoid overwhelming the server
    time.sleep(0.1)  # 100ms delay between requests

# Print summary of responses
print("\nSummary of Inference Calls:")
for resp in responses:
    print(f"\nCall {resp['call']}:")
    if resp["status"] == "success":
        print(f"Response: {resp['response']}")
    else:
        print(f"Error: {resp['error']}")
        print(f"Error Details: {resp['error_details']}")