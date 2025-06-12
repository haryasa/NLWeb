#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
rss_to_jsonld.py  –  Convert an RSS feed to one-line-per-post JSON-LD (BlogPosting)

usage:
    python rss_to_jsonld.py https://example.com/blog/rss.xml   > blog.ndjson
    python rss_to_jsonld.py path/to/local.xml                 > blog.ndjson
"""

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

import feedparser

ISO_FMT = "%Y-%m-%dT%H:%M:%S%z"


def iso8601(struct_time):
    """Convert feedparser’s time struct → ISO-8601 string (UTC)."""
    if not struct_time:
        return None
    dt = datetime(*struct_time[:6], tzinfo=timezone.utc)
    return dt.strftime(ISO_FMT)


def parse_feed(source):
    """
    Parse a feed from URL, file path or stdin.
    Returns (channel_meta, [entry_dicts…]).
    """
    if source == "-":                               # read from stdin
        raw = sys.stdin.read()
        feed = feedparser.parse(raw)
    elif Path(source).exists():                     # local file
        feed = feedparser.parse(Path(source).read_bytes())
    else:                                           # assume URL
        feed = feedparser.parse(source)

    channel = feed.feed
    channel_meta = {
        "@type": "Blog",
        "name":  channel.get("title", ""),
        "description": channel.get("subtitle", "") or channel.get("description", ""),
        "url":   channel.get("link", "")
    }
    return channel_meta, feed.entries


def entry_to_jsonld(entry, channel_meta):
    """Build a JSON-LD BlogPosting object from one feed entry."""
    # Pick first media:content or media:thumbnail if present
    img = None
    if entry.get("media_content"):
        img = entry.media_content[0].get("url")
    elif entry.get("media_thumbnail"):
        img = entry.media_thumbnail[0].get("url")

    jsonld = {
        "@context": "https://schema.org",
        "@type": "BlogPosting",
        # headline maps best to <title>
        "headline": entry.get("title", "").strip(),
        "description": (entry.get("summary", "") or entry.get("description", "")).strip(),
        "datePublished": iso8601(entry.get("published_parsed")),
        "url": entry.get("link", "").strip(),
        # image may be None if feed provides none
        **({"image": img} if img else {}),
        # Relate post to its parent blog
        "isPartOf": channel_meta,
    }
    return jsonld


def main():
    ap = argparse.ArgumentParser(description="Convert RSS → newline-delimited JSON-LD BlogPosting objects")
    ap.add_argument("source", help="Feed URL, local file path, or '-' to read from stdin")
    args = ap.parse_args()

    channel_meta, entries = parse_feed(args.source)

    for e in entries:
        print(json.dumps(entry_to_jsonld(e, channel_meta), ensure_ascii=False))


if __name__ == "__main__":
    main()
