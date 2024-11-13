"""Selenium-based website heartbeat checker.

Uses HTTPS by default."""
from __future__ import annotations

import json
import os
import urllib.parse

from aws_synthetics.common import synthetics_logger as logger
from aws_synthetics.selenium import synthetics_webdriver as syn_webdriver
from selenium.webdriver.common.by import By

PREFERRED_SCHEME = os.environ.get("URL_SCHEME", "https")
TAKE_SCREENSHOT = os.environ.get("TAKE_SCREENSHOT", "True") == "True"
URLS = json.loads(os.environ["WEBSITE_URLS"])
RESPONSE_OK = range(200, 300)

def set_url_scheme(url: str) -> str:
    """Set the URL scheme of a provided endpoint."""
    parsed = urllib.parse.urlparse(url)

    if not parsed.scheme or parsed.scheme != PREFERRED_SCHEME:
        url = f"{PREFERRED_SCHEME}://{url}"
    return url

def handler(event: dict, _: dict) -> None:
    """Navigates to various pages."""
    logger.debug("Lambda function called with\n%s", json.dumps(event, indent=4))
    logger.info("Selenium Python browser canary.")

    syn_webdriver.add_user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                                 "AppleWebKit/537.36 (KHTML, like Gecko) "
                                 "Chrome/130.0.0.0 Safari/537.36")
    browser = syn_webdriver.Chrome()
    urls = list(map(set_url_scheme, URLS))
    results = {}
    for idx, url in enumerate(urls):
        logger.info(f"Navigating to {url} [{idx+1}/{len(urls)}]")
        browser.get(url)

        if TAKE_SCREENSHOT:
            browser.save_screenshot(f"{idx}.png")

        response_code = syn_webdriver.get_http_response(url)
        if isinstance(response_code, int) and response_code in range(200, 300):
            logger.info("PASSED")
            results[url] = True
        else:
            logger.info("FAILED")
            results[url] = False
    if not all(results.values()):
        msg = "All pages did not load!"
        raise RuntimeError(msg)
    logger.info("Canary successfully executed.")

