#!/usr/bin/env python3
import sys
import re

def parse_version(input_text):
    """
    Parses commit message, tag, or version input string.
    Expected format: Build:v1.0.0 or v1.0.0 or 1.0.0
    Returns dict:
      is_release (bool)
      version (str)
      tag (str)
      source (str)
    """
    if not input_text:
        return {'is_release': False, 'version': '', 'tag': '', 'source': 'none'}

    text = input_text.strip()

    # 1. Check for standard commit format: Build:v1.0.0 or Build:1.0.0
    commit_match = re.search(r'(?:^|\n)\s*Build:v?([0-9]+\.[0-9]+\.[0-9]+(?:[-+][a-zA-Z0-9.]+)?)\s*(?:\n|$)', text)
    if commit_match:
        ver = commit_match.group(1)
        return {
            'is_release': True,
            'version': ver,
            'tag': f'v{ver}',
            'source': 'commit_message'
        }

    # 2. Check for release tag format v1.0.0 or clean semver 1.0.0
    tag_match = re.match(r'^v?([0-9]+\.[0-9]+\.[0-9]+(?:[-+][a-zA-Z0-9.]+)?)$', text)
    if tag_match:
        ver = tag_match.group(1)
        return {
            'is_release': True,
            'version': ver,
            'tag': f'v{ver}',
            'source': 'tag_or_input'
        }

    return {'is_release': False, 'version': '', 'tag': '', 'source': 'invalid'}

if __name__ == '__main__':
    msg = sys.argv[1] if len(sys.argv) > 1 else ''
    res = parse_version(msg)
    # Output GitHub step outputs format if GITHUB_OUTPUT environment variable exists
    print(f"IS_RELEASE={str(res['is_release']).lower()}")
    print(f"VERSION={res['version']}")
    print(f"TAG={res['tag']}")
    print(f"SOURCE={res['source']}")
