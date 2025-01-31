"""Eventbridge-to-Chatbot notification Transformer.

This simple Lambda function accepts EventBridge Events and
converts them into notifications that AWS Chatbot can interpret.
"""

from __future__ import annotations

import json
import logging
import os
import re
from dataclasses import asdict, dataclass, field
from typing import Any, TypeVar

import boto3

T = TypeVar("T", bound="AWSEvent")
LOGGER = logging.getLogger(__name__)
PROMPT = """INSTRUCTIONS:
You are a Slack bot that summarizes JSON events. Respond only in JSON format as shown below. No other format will be accepted.
FORMAT:
{
  "title": ":category_emoji: A summarizing title",
  "description": "A single sentence describing the event.",
  "keywords": ["keyword-1", "keyword-2", "keyword-3"],
  "threadId": "Use the ActivityId or another relevant ID.",
  "nextSteps": ["Next step 1.", "Next step 2.", "Next step 3."],
  "summary": ":category_emoji: A brief overview of what occurred."
}
NOTES:
title: Use a category emoji and a summarizing title.
description: One sentence summarizing the event and indicating affected resources.
keywords: List relevant keywords in kebab-case (e.g., ec2, instance-terminate).
threadId: Use the ActivityId or other relevant ID (e.g., Job ID, Auto Scaling Group name).
nextSteps: List actionable steps, each as a complete sentence.
summary: Use a category emoji and provide a concise event overview.

EMOJI CATEGORIES:
:red_circle: Negative
:large_orange_circle: Neutral
:large_green_circle: Positive

EXAMPLE INPUT:
{
  "detail-type": "EC2 Instance Terminate Unsuccessful",
  "source": "aws.autoscaling",
  "account": "123456789012",
  "time": "2015-12-01T23:34:57Z",
  "region": "us-east-1",
  "resources": ["arn:aws:autoscaling:us-east-1:123456789012:autoScalingGroup:cf5ebd9c-8e2a-4197-abe2-2fb94e8d1f87:autoScalingGroupName/sampleTermUnsucASG", "arn:aws:ec2:us-east-1:123456789012:instance/i-b188560f"],
  "detail": {
    "StatusCode": "InProgress",
    "Description": "Terminating EC2 instance: i-b188560f",
    "AutoScalingGroupName": "sampleTermUnsucASG",
    "ActivityId": "c1a8f6ce-82e8-4517-96ba-67d1999ceee4"
  }
}
EXAMPLE OUTPUT:
{
  "title": ":red_circle: EC2 Instance Terminate Unsuccessful",
  "description": "The termination of EC2 instance `i-b188560f` in Auto Scaling group `sampleTermUnsucASG` failed.",
  "keywords": ["ec2", "instance-terminate", "auto-scaling-group", "failure"],
  "threadId": "c1a8f6ce-82e8-4517-96ba-67d1999ceee4",
  "nextSteps": ["Investigate the cause of failure.", "Check the Auto Scaling group settings.", "Review EC2 instance logs."],
  "summary": "EC2 instance `i-b188560f` termination failed in Auto Scaling group sampleTermUnsucASG."
}
IMPORTANT:
- Respond only in the specified JSON format.
- Use ActivityId or another relevant ID for threadId.
- Make use of formatting to highlight key terms in the "description" and "summary" fields.
- Ensure next steps are actionable and written in full sentences.

EVENT DETAILS:
"""


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

    title: str
    description: str
    keywords: list[str] = field(default_factory=list)
    nextSteps: list[str] = field(default_factory=list)
    textType: str = "client-markdown"


@dataclass
class ChatBotNotificationMetadata:
    """Contains the metadata for Chatbot notifications."""

    threadId: str
    summary: str


@dataclass
class ChatBotNotificationData:
    """Contains the required headers for Chatbot notifications."""

    content: ChatBotNotificationContent
    metadata: ChatBotNotificationMetadata
    version: str = "1.0"
    source: str = "custom"


class ChatBotNotification:
    """Standard custom AWS ChatBot Notification."""

    def __init__(self: ChatBotNotification, *, data: ChatBotNotificationData) -> None:
        """Initialise the Notification object."""
        self.__data = data

    @property
    def data(self: ChatBotNotification) -> ChatBotNotificationData:
        return self.__data

    @data.setter
    def data(self: ChatBotNotification, data: ChatBotNotificationData) -> None:
        if not isinstance(data, ChatBotNotificationData):
            msg = f"Expected ChatBotNotificationData, got {type(data)}"
            raise TypeError(msg)
        self.__data = data

    def send_message(self: ChatBotNotification) -> None:
        """Send the compiled message to SNS."""
        client = boto3.client("sns")
        client.publish(
            Message=json.dumps(asdict(self.data)),
            TopicArn=os.environ["TOPIC_ARN"],
        )


@dataclass(kw_only=True)
class BedrockRequest:
    """Request to the Bedrock runtime."""

    modelId: str
    accept: str
    contentType: str
    body: str


@dataclass(kw_only=True)
class BedrockResponse:
    """Response from the Bedrock runtime."""

    title: str
    description: str
    keywords: list[str]
    nextSteps: list[str]
    threadId: str
    summary: str


@dataclass
class AWSNovaPrompt:
    """Prompt for the AWS Nova LLM request."""

    text: str


@dataclass
class AWSNovaMessage:
    """Message for the AWS Nova LLM request."""

    content: list[AWSNovaPrompt]
    role: str = "user"


@dataclass
class AWSNovaRequestBody:
    """Body of the AWS Bedock API request."""

    messages: list[AWSNovaMessage]


class BedrockHandler:
    """Handler that interacts with AWS Bedrock."""

    def __init__(self: BedrockHandler) -> None:
        """Initialise the BedrockHandler."""
        self.__bedrock_runtime = boto3.client(
            "bedrock-runtime",
            region_name="us-east-1",
        )

    def generate_request(
        self: BedrockHandler,
        event: EventBridgeEvent,
    ) -> BedrockRequest:
        """Generate a request for the Bedrock runtime."""
        return BedrockRequest(
            modelId="amazon.nova-micro-v1:0",
            accept="application/json",
            contentType="application/json",
            body=json.dumps(
                asdict(
                    AWSNovaRequestBody(
                        messages=[
                            AWSNovaMessage(
                                content=[
                                    AWSNovaPrompt(
                                        text=PROMPT + json.dumps(asdict(event)),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ),
            ),
        )

    def get_response(
        self: BedrockHandler,
        event: EventBridgeEvent,
    ) -> BedrockResponse:
        """Get a response from the Bedrock runtime."""
        response = self.__bedrock_runtime.invoke_model(
            **asdict(self.generate_request(event)),
        )
        body = json.loads(response.get("body").read())
        return BedrockResponse(
            **json.loads(
                body.get("output").get("message").get("content")[0].get("text"),
            ),
        )


class EventBridgeNotification(ChatBotNotification):
    """Generic EventBridge notification."""

    def __init__(self: EventBridgeNotification, event: EventBridgeEvent) -> None:
        """Initialize the notification."""
        self.__event = event
        super().__init__(data=self.__parse_event())

    def __parse_event(self: EventBridgeNotification) -> ChatBotNotificationData:
        """Parse the event into a ChatBotNotificationData object."""
        bedrock = BedrockHandler()
        response = bedrock.get_response(self.event)
        return ChatBotNotificationData(
            content=ChatBotNotificationContent(
                title=response.title,
                description=response.description,
                keywords=response.keywords,
                nextSteps=response.nextSteps,
            ),
            metadata=ChatBotNotificationMetadata(
                threadId=response.threadId,
                summary=response.summary,
            ),
        )

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


def handler(event: dict, _: dict) -> None:
    """Send the eventbridge event."""
    EventBridgeNotification.from_event(event).send_message()
