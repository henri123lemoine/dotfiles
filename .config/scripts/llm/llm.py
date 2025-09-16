#!/usr/bin/env python3

import os
import sys
import json
import urllib.request
import urllib.parse
import argparse


def load_prompt(prompt_tag):
    """Load system prompt from prompts directory."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    prompts_dir = os.path.join(script_dir, "prompts")
    prompt_file = os.path.join(prompts_dir, f"{prompt_tag}.txt")

    try:
        with open(prompt_file, "r") as f:
            return f.read().strip()
    except FileNotFoundError:
        print(
            f"Error: Prompt '{prompt_tag}' not found in {prompts_dir}", file=sys.stderr
        )
        print(f"Available prompts:", file=sys.stderr)
        try:
            for file in os.listdir(prompts_dir):
                if file.endswith(".txt"):
                    print(f"  - {file[:-4]}", file=sys.stderr)
        except:
            pass
        sys.exit(1)


def make_api_call(message, api_key, system_prompt):
    """Make API call to OpenAI's GPT API."""
    url = "https://api.openai.com/v1/chat/completions"

    data = {
        "model": "gpt-5-mini",
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": message},
        ],
        "max_completion_tokens": 8000,
        # Keys for older models like gpt-4o
        # "max_tokens": 10000,
        # "temperature": 0.7,
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
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8")
        return f"HTTP Error {e.code}: {error_body}"
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
    # Parse command line arguments
    parser = argparse.ArgumentParser(description="LLM CLI with prompt library support")
    parser.add_argument(
        "-p", "--prompt", default="default", help="Prompt tag to use (default: default)"
    )
    parser.add_argument(
        "--list-prompts", action="store_true", help="List available prompts and exit"
    )

    args = parser.parse_args()

    # List prompts if requested
    if args.list_prompts:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        prompts_dir = os.path.join(script_dir, "prompts")
        print("Available prompts:")
        try:
            for file in sorted(os.listdir(prompts_dir)):
                if file.endswith(".txt"):
                    prompt_name = file[:-4]
                    print(f"  - {prompt_name}")
        except FileNotFoundError:
            print("  No prompts directory found")
        sys.exit(0)

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

    # Load the specified prompt
    system_prompt = load_prompt(args.prompt)

    # Read input from stdin
    try:
        input_text = sys.stdin.read().strip()
    except KeyboardInterrupt:
        sys.exit(0)

    if not input_text:
        print("Error: No input provided", file=sys.stderr)
        print(
            "Usage: echo 'your question' | python llm.py [-p prompt_tag]",
            file=sys.stderr,
        )
        sys.exit(1)

    # Make API call and print response
    response = make_api_call(input_text, api_key, system_prompt)
    print(response)


if __name__ == "__main__":
    main()
