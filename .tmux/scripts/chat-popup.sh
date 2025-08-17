#!/usr/bin/env bash

convo=""    # full chat history
resp=""     # last assistant reply

while true; do
    # 1) ask your turn
    read -p "You: " line
    [[ -z "$line" || "$line" = "/exit" ]] && break
    
    # 2) append user turn
    convo+=$'\n'"Human: $line"
    
    # 3) get assistant reply
    resp=$(printf "%s\n" "$convo" | python3 ~/.tmux/scripts/llm/llm.py -p command)
    
    # 4) display it
    echo
    echo "GPT: $resp"
    echo
    
    # 5) append assistant turn
    convo+=$'\n'"Assistant: $resp"
done

# 6) on exit, offer to copy last response
echo
read -n1 -s -r -p "Press 'c' to copy last GPT reply, any other key to close..." key
if [[ "$key" = "c" ]]; then
    printf "%s" "$resp" | pbcopy
fi
