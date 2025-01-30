"""Eventbridge-to-Chatbot notification Transformer.

This simple Lambda function accepts EventBridge Events and
converts them into notifications that AWS Chatbot can interpret.
"""

from __future__ import annotations

import json
import logging
import os
import re
from abc import ABC
from dataclasses import asdict, dataclass, field
from typing import Any, TypeVar

import boto3

T = TypeVar("T", bound="AWSEvent")
LOGGER = logging.getLogger(__name__)
PROMPT = """You are a chat bot that needs to provide concise summaries in sentence format based on JSON events that are received by you. You must provide contextual information to help readers understand which resources are involved.
If the event is negative (e.g. warning, error), then indicate with a :rotating_light:. If the event is neutral (e.g., information, in-progress), then indicate with a :bulb:. If the event is positive (e.g. complete, success) then indicate with a :white_check_mark:.
JSON EVENT:
{event_string}""" 

@dataclass(kw_only=True)
class AWSEvent:
    """Abstract class for all dict-handling events."""

    @classmethod
    def from_dict(cls: type[T], data: dict[str, Any]) -> T:
        """Construct a dict from its component keys."""
        cls._normalize_keys(data)
        cls._check_missing_keys(data)
        cls._drop_excess_keys(data)
        return cls(**data)

    @staticmethod
    def _normalize_keys(data: dict[str, Any]) -> None:
        """Normalize the keys of the incoming data in place."""
        for k in list(data.keys()):
            # Catch camelCase patterns
            if re.search(r"(?!^)[A-Z]", k):
                pattern = r"(?!^)([A-Z])"
                repl = r"_\1"
            # or kebab-case patterns
            elif re.search(r"-", k):
                pattern = "-"
                repl = "_"
            # replace key and make lowercase
            # (Pascal_Case, camel_Case) -> (pascal_case, camel_case)
            else:
                pattern = ""
                repl = ""
            data[re.sub(pattern, repl, k).lower()] = data.pop(k)

    @classmethod
    def _check_missing_keys(cls: type[T], data: dict[str, Any]) -> None:
        """Check for missing keys within the incoming data."""
        missing_keys = set(cls.__dataclass_fields__.keys()).difference(data.keys())
        if missing_keys:
            msg = f"The following keys are missing from source event: {missing_keys}"
            raise ValueError(msg)

    @classmethod
    def _drop_excess_keys(cls: type[T], data: dict[str, Any]) -> None:
        """Drop excess keys from the event dict."""
        excess_keys = set(data.keys()).difference(cls.__dataclass_fields__.keys())
        for k in excess_keys:
            data.pop(k)


@dataclass(kw_only=True)
class EventBridgeEvent(AWSEvent):
    """Container for eventbridge events."""

    account: str
    region: str
    source: str
    detail_type: str
    detail: dict[str, str]
    resources: list[str]


@dataclass
class ChatBotNotificationContent:
    """Contains the content that Chatbot displays."""

    description: str
    textType: str = "client-markdown"


@dataclass
class ChatBotNotificationData:
    """Contains the required headers for Chatbot notifications."""

    content: ChatBotNotificationContent
    version: str = "1.0"
    source: str = "custom"


class ChatBotNotification(ABC):
    """Standard custom AWS ChatBot Notification."""

    def __init__(self: ChatBotNotification, *, text: str = "") -> None:
        """Initialise the Notification object."""
        self.__text = text

    @property
    def text(self: ChatBotNotification) -> str:
        """Return the raw text of the notification."""
        return self.__text

    @text.setter
    def text(self: ChatBotNotification, text: str) -> None:
        """Set the text data for the notification to a new value."""
        if not isinstance(text, str):
            msg = "Notification text must be a string!"
            raise TypeError(msg)
        self.__text = text

    def send_message(self: ChatBotNotification) -> None:
        """Send the compiled message to SNS."""
        client = boto3.client("sns")
        client.publish(
            Message=json.dumps(
                asdict(
                    ChatBotNotificationData(
                        content=ChatBotNotificationContent(description=self.__text),
                    ),
                ),
            ),
            TopicArn=os.environ["TOPIC_ARN"],
        )

@dataclass
class AWSNovaPrompt:
    text: str

@dataclass
class AWSNovaMessage:
    content: list[AWSNovaPrompt]
    role: str = "user"

@dataclass
class AWSNovaBody:
    messages: list[AWSNovaMessage]

class BedrockHandler:
    """Handler that interacts with AWS Bedrock."""

    def __init__(self: BedrockHandler) -> None:
        """Initialise the BedrockHandler."""
        self.__bedrock_runtime = boto3.client(
            "bedrock-runtime",
            region_name="us-east-1",
        )

    def generate_request(self: BedrockHandler, event: EventBridgeEvent) -> dict:
        """Generate a request for the Bedrock runtime."""
        return {
            "modelId": "amazon.nova-micro-v1:0",
            "accept": "application/json",
            "contentType": "application/json",
            "body": json.dumps(
                asdict(
                    AWSNovaBody(
                        messages=[AWSNovaMessage(content=[AWSNovaPrompt(text=PROMPT.format(event_string=json.dumps(asdict(event))))])],
                    ),
                ),
            ),
        }

    def get_response(self: BedrockHandler, event: EventBridgeEvent) -> str:
        """Get a response from the Bedrock runtime."""
        print(self.generate_request(event))
        response = self.__bedrock_runtime.invoke_model(**self.generate_request(event))
        body = json.loads(response.get("body").read())
        return body.get("output").get("message").get("content")[0].get("text")


class EventBridgeNotification(ChatBotNotification):
    """Generic EventBridge notification."""

    def __init__(self: EventBridgeNotification, event: EventBridgeEvent) -> None:
        """Initialize the notification."""
        self.__event = event

    @property
    def event(self: EventBridgeNotification) -> EventBridgeEvent:
        """Return the event associated with the notification."""
        return self.__event

    @classmethod
    def from_event(
        cls: type[EventBridgeNotification],
        event: dict,
    ) -> EventBridgeNotification:
        """Create a notification object from an EventBridge event."""
        return cls(EventBridgeEvent.from_dict(event))

    def compose_message(
        self: EventBridgeNotification,
        *,
        use_ai: bool = False,
    ) -> None:
        """Compile the EventBridge event into a formatted string."""
        if use_ai:
            bedrock = BedrockHandler()
            self.text = bedrock.get_response(event=self.event)
        else:
            detail = "\n".join(f"{k}: {v}" for k, v in self.event.detail.items())
            resources = "\n".join(resource for resource in self.event.resources)
            self.text = (
                f"*:loudspeaker: [{self.event.source.upper()}]: "
                f"{self.event.detail_type} :loudspeaker:*\n\n"
            )
            self.text += f"*AWS Account*\n```{self.event.account}```\n\n"
            self.text += f"*AWS Region* \n```{self.event.region}```\n\n"
            self.text += f"*Resources*\n```{resources}```\n\n"
            self.text += f"*Detail*\n```{detail}```"

    def send_message(self: EventBridgeNotification, *, use_ai: bool = False) -> None:
        """Send the EventBridge notification to ChatBot."""
        self.compose_message(use_ai=use_ai)
        return super().send_message()


def handler(event: dict, _: dict) -> None:
    """Send the eventbridge event."""
    EventBridgeNotification.from_event(event).send_message(
        use_ai=os.environ.get("USE_AI", "True") == "True",
    )
