#!/usr/bin/env python3
"""Small local checks for the static GitHub Pages profile."""
import json
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlparse
from xml.etree import ElementTree


ROOT = Path(__file__).resolve().parent.parent


class Page(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.ids = set()
        self.fragments = []
        self.images_without_alt = []
        self.h1_count = 0
        self.language = None
        self.canonicals = []
        self.json_ld = []
        self.in_json_ld = False
        self.json_ld_text = ""

    def handle_starttag(self, tag, attributes):
        attrs = dict(attributes)
        if "id" in attrs:
            self.ids.add(attrs["id"])
        if tag == "html":
            self.language = attrs.get("lang")
        if tag == "h1":
            self.h1_count += 1
        if tag == "a":
            fragment = urlparse(attrs.get("href", "")).fragment
            if attrs.get("href", "").startswith("#") and fragment:
                self.fragments.append(fragment)
        if tag == "img" and not attrs.get("alt"):
            self.images_without_alt.append(attrs.get("src"))
        if tag == "link" and attrs.get("rel") == "canonical":
            self.canonicals.append(attrs.get("href"))
        if tag == "script" and attrs.get("type") == "application/ld+json":
            self.in_json_ld = True
            self.json_ld_text = ""

    def handle_data(self, data):
        if self.in_json_ld:
            self.json_ld_text += data

    def handle_endtag(self, tag):
        if tag == "script" and self.in_json_ld:
            self.json_ld.append(json.loads(self.json_ld_text))
            self.in_json_ld = False


home = (ROOT / "index.html").read_text()
not_found = (ROOT / "404.html").read_text()
readme = (ROOT / "README.md").read_text()
page = Page()
page.feed(home)
assert page.language == "en", "Home needs an explicit English language"
assert page.h1_count == 1, "Home needs one primary heading"
assert not page.images_without_alt, "Every image needs alternative text"
assert not (set(page.fragments) - page.ids), "Broken in-page navigation"
assert page.canonicals == ["https://hiagokinlevi.github.io/"], "Incorrect canonical URL"
assert len(page.json_ld) == 1 and page.json_ld[0]["@type"] == "Person", "Invalid Person structured data"
assert "OpenCyber Academy" in home and "opencyber.academy" in home, "Academy entry point missing"
assert "CyberABC" not in home + not_found + readme, "Legacy project name remains"
assert "noindex,follow" in not_found, "404 page must stay out of the search index"
sitemap = ElementTree.parse(ROOT / "sitemap.xml")
namespace = {"s": "http://www.sitemaps.org/schemas/sitemap/0.9"}
urls = [node.text for node in sitemap.findall(".//s:loc", namespace)]
assert urls == ["https://hiagokinlevi.github.io/"], "Unexpected sitemap URLs"
assert "https://hiagokinlevi.github.io/sitemap.xml" in (ROOT / "robots.txt").read_text(), "Sitemap missing from robots"
assert (ROOT / "favicon.svg").exists() and all('href="/favicon.svg"' in page for page in (home, not_found)), "Favicon missing"
print("Static profile validation passed: navigation, metadata, structured data, sitemap and legacy name")
