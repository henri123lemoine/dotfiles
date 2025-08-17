#!/usr/bin/env python3

import os
import sys
import json
import urllib.request
import urllib.parse


def make_api_call(message, api_key):
    """Make API call to OpenAI's GPT API."""
    url = "https://api.openai.com/v1/chat/completions"

    # Add system prompt for conciseness
    system_prompt = """You are a concise assistant. Be brief and direct.

For command requests (how to do X, what command for Y, etc.), output ONLY the command with no explanation unless specifically asked.

For other questions, give short, clear answers. Skip pleasantries and filler."""

    data = {
        "model": "gpt-4o",
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": message},
        ],
        "max_tokens": 10000,
        "temperature": 0.7,
    }

    # Prepare the request
    json_data = json.dumps(data).encode("utf-8")

    req = urllib.request.Request(
        url,
        data=json_data,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
        },
    )

    try:
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read().decode("utf-8"))

        if "error" in result:
            return f"API Error: {result['error'].get('message', 'Unknown error')}"

        return result["choices"][0]["message"]["content"]

    except Exception as e:
        return f"Error: {e}"


def load_env():
    """Load environment variables from .env file in script directory."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    env_path = os.path.join(script_dir, ".env")

    try:
        with open(env_path, "r") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    key, value = line.split("=", 1)
                    # Remove quotes if present
                    value = value.strip().strip('"').strip("'")
                    os.environ[key.strip()] = value
    except FileNotFoundError:
        pass  # .env file is optional


def main():
    # Load .env file first
    load_env()

    # Check for API key
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        print("Error: OPENAI_API_KEY not found", file=sys.stderr)
        print(
            "Please set your OpenAI API key in .env file or environment:",
            file=sys.stderr,
        )
        print("echo 'OPENAI_API_KEY=your-api-key-here' > .env", file=sys.stderr)
        sys.exit(1)

    # Read input from stdin
    try:
        input_text = sys.stdin.read().strip()
    except KeyboardInterrupt:
        sys.exit(0)

    if not input_text:
        print("Error: No input provided", file=sys.stderr)
        print("Usage: echo 'your question' | python gpt4_cli.py", file=sys.stderr)
        sys.exit(1)

    # Make API call and print response
    response = make_api_call(input_text, api_key)
    print(response)


if __name__ == "__main__":
    main()
