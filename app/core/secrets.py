"""At-rest protection for locally stored LLM credentials."""

from __future__ import annotations

import base64
import ctypes
import os
from ctypes import wintypes
from pathlib import Path

from cryptography.fernet import Fernet, InvalidToken

from app.core.config import ROOT_DIR


_KEY_PATH = ROOT_DIR / "data" / ".app-secret-key"
_DPAPI_PREFIX = "dpapi:v1:"
_FERNET_PREFIX = "fernet:v1:"


class _DataBlob(ctypes.Structure):
    _fields_ = [("cbData", wintypes.DWORD), ("pbData", ctypes.POINTER(ctypes.c_byte))]


def _protect_windows(value: bytes) -> bytes:
    crypt32 = ctypes.WinDLL("Crypt32.dll", use_last_error=True)
    kernel32 = ctypes.WinDLL("Kernel32.dll", use_last_error=True)
    crypt32.CryptProtectData.argtypes = [
        ctypes.POINTER(_DataBlob),
        wintypes.LPCWSTR,
        ctypes.POINTER(_DataBlob),
        wintypes.LPVOID,
        wintypes.LPVOID,
        wintypes.DWORD,
        ctypes.POINTER(_DataBlob),
    ]
    crypt32.CryptProtectData.restype = wintypes.BOOL
    kernel32.LocalFree.argtypes = [wintypes.HLOCAL]
    input_buffer = ctypes.create_string_buffer(value)
    input_blob = _DataBlob(len(value), ctypes.cast(input_buffer, ctypes.POINTER(ctypes.c_byte)))
    output_blob = _DataBlob()
    if not crypt32.CryptProtectData(ctypes.byref(input_blob), None, None, None, None, 0, ctypes.byref(output_blob)):
        raise ctypes.WinError(ctypes.get_last_error())
    try:
        return ctypes.string_at(output_blob.pbData, output_blob.cbData)
    finally:
        kernel32.LocalFree(output_blob.pbData)


def _unprotect_windows(value: bytes) -> bytes:
    crypt32 = ctypes.WinDLL("Crypt32.dll", use_last_error=True)
    kernel32 = ctypes.WinDLL("Kernel32.dll", use_last_error=True)
    crypt32.CryptUnprotectData.argtypes = [
        ctypes.POINTER(_DataBlob),
        ctypes.POINTER(wintypes.LPWSTR),
        ctypes.POINTER(_DataBlob),
        wintypes.LPVOID,
        wintypes.LPVOID,
        wintypes.DWORD,
        ctypes.POINTER(_DataBlob),
    ]
    crypt32.CryptUnprotectData.restype = wintypes.BOOL
    kernel32.LocalFree.argtypes = [wintypes.HLOCAL]
    input_buffer = ctypes.create_string_buffer(value)
    input_blob = _DataBlob(len(value), ctypes.cast(input_buffer, ctypes.POINTER(ctypes.c_byte)))
    output_blob = _DataBlob()
    description = wintypes.LPWSTR()
    if not crypt32.CryptUnprotectData(
        ctypes.byref(input_blob),
        ctypes.byref(description),
        None,
        None,
        None,
        0,
        ctypes.byref(output_blob),
    ):
        raise ctypes.WinError(ctypes.get_last_error())
    try:
        return ctypes.string_at(output_blob.pbData, output_blob.cbData)
    finally:
        if description:
            kernel32.LocalFree(description)
        kernel32.LocalFree(output_blob.pbData)


def _fernet() -> Fernet:
    _KEY_PATH.parent.mkdir(parents=True, exist_ok=True)
    if not _KEY_PATH.exists():
        descriptor = os.open(_KEY_PATH, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        try:
            with os.fdopen(descriptor, "wb") as stream:
                stream.write(Fernet.generate_key())
        finally:
            try:
                _KEY_PATH.chmod(0o600)
            except OSError:
                pass
    return Fernet(_KEY_PATH.read_bytes().strip())


def encrypt_secret(value: str) -> str:
    if not value:
        return ""
    raw = value.encode("utf-8")
    if os.name == "nt":
        encrypted = _protect_windows(raw)
        return _DPAPI_PREFIX + base64.urlsafe_b64encode(encrypted).decode("ascii")
    return _FERNET_PREFIX + _fernet().encrypt(raw).decode("ascii")


def decrypt_secret(value: str) -> str:
    if not value:
        return ""
    if value.startswith(_DPAPI_PREFIX):
        raw = base64.urlsafe_b64decode(value.removeprefix(_DPAPI_PREFIX))
        if os.name != "nt":
            raise ValueError("该密钥由 Windows DPAPI 保护，当前系统无法解密")
        return _unprotect_windows(raw).decode("utf-8")
    if value.startswith(_FERNET_PREFIX):
        try:
            return _fernet().decrypt(value.removeprefix(_FERNET_PREFIX).encode("ascii")).decode("utf-8")
        except (InvalidToken, ValueError) as exc:
            raise ValueError("本地 API Key 无法解密") from exc
    # 兼容历史明文行；调用方会在下一次读取设置时迁移它。
    return value


def is_encrypted(value: str) -> bool:
    return value.startswith((_DPAPI_PREFIX, _FERNET_PREFIX))
