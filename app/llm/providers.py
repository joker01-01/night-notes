"""可插拔 LLM Provider：业务层只依赖 chat(messages) 接口。"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol, TypedDict

import httpx


class ChatMessage(TypedDict):
    role: str
    content: str


class LLMProvider(Protocol):
    def chat(self, messages: list[ChatMessage]) -> str:
        """发送一轮对话并返回纯文本回复。"""


@dataclass(frozen=True)
class ProviderConfig:
    provider: str
    api_key: str
    base_url: str
    model: str


class LLMRequestError(RuntimeError):
    """把上游网络与 API 错误转成可显示的业务错误。"""


def _safe_error_message(exc: Exception) -> str:
    """避免把上游 URL、响应体等细节直接回传给客户端。"""
    name = type(exc).__name__
    return f"{name}: 上游请求失败"


class OpenAICompatibleProvider:
    """适配 OpenAI Chat Completions 协议的 API。"""

    def __init__(self, config: ProviderConfig) -> None:
        self.config = config

    def chat(self, messages: list[ChatMessage]) -> str:
        if not self.config.api_key:
            raise LLMRequestError("尚未配置 LLM API Key，请在设置页填写后重试。")
        url = f"{self.config.base_url.rstrip('/')}/chat/completions"
        try:
            with httpx.Client(trust_env=False, follow_redirects=False, timeout=60) as client:
                response = client.post(
                    url,
                    headers={"Authorization": f"Bearer {self.config.api_key}"},
                    json={"model": self.config.model, "messages": messages, "temperature": 0.4},
                )
            response.raise_for_status()
            content = response.json()["choices"][0]["message"]["content"]
            if not content:
                raise KeyError("empty content")
            return str(content)
        except (httpx.HTTPError, KeyError, TypeError, ValueError) as exc:
            raise LLMRequestError(f"LLM 请求失败（{_safe_error_message(exc)}）") from exc


class DeepSeekProvider(OpenAICompatibleProvider):
    """DeepSeek 默认实现。

    DeepSeek 使用 OpenAI 兼容协议，因此只需换 model/base_url 即可迁移至未来
    的 DeepSeek v4 或其他 DeepSeek 模型；业务代码无需改动。
    """


class OllamaProvider:
    """预留并实现 Ollama 本地 /api/chat 协议，适用于完全离线模型。"""

    def __init__(self, config: ProviderConfig) -> None:
        self.config = config

    def chat(self, messages: list[ChatMessage]) -> str:
        url = f"{self.config.base_url.rstrip('/')}/api/chat"
        try:
            with httpx.Client(trust_env=False, follow_redirects=False, timeout=120) as client:
                response = client.post(
                    url,
                    json={"model": self.config.model, "messages": messages, "stream": False},
                )
            response.raise_for_status()
            return str(response.json()["message"]["content"])
        except (httpx.HTTPError, KeyError, TypeError, ValueError) as exc:
            raise LLMRequestError(f"Ollama 请求失败（{_safe_error_message(exc)}）") from exc


def create_provider(config: ProviderConfig) -> LLMProvider:
    normalized = config.provider.lower().strip()
    if normalized == "deepseek":
        return DeepSeekProvider(config)
    if normalized in {"openai", "openai_compatible"}:
        return OpenAICompatibleProvider(config)
    if normalized == "ollama":
        return OllamaProvider(config)
    raise LLMRequestError(f"不支持的 LLM Provider：{config.provider}")
