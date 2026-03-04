import os
import sys
from unittest.mock import MagicMock, patch

import pytest

sys.path.insert(0, os.path.dirname(__file__))


@pytest.fixture(autouse=True)
def clean_env():
    old = os.environ.pop("CLAUDE_PR_REVIEW_LOOP", None)
    yield
    if old is not None:
        os.environ["CLAUDE_PR_REVIEW_LOOP"] = old
    else:
        os.environ.pop("CLAUDE_PR_REVIEW_LOOP", None)


@pytest.fixture(autouse=True)
def suppress_hook_logging():
    import pr_review_loop

    with patch.object(pr_review_loop, "log", MagicMock()):
        yield
