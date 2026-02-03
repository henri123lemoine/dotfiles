Fetch and apply the latest PR review feedback:

1. Get current PR info with `gh pr view --json number,url`
2. Get comments with `gh api repos/{owner}/{repo}/issues/{number}/comments`
3. Get review comments with `gh api repos/{owner}/{repo}/pulls/{number}/comments`
4. Filter to bot feedback (accounts ending in [bot]) since the last commit
5. Apply the feedback, run tests, and push
6. Summarize what you changed
