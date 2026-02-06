"""
Gene1799 Core - Python Package

Gene1799 Art Corporation
License: 16/L4090879L
"""

from .signing import (
    signer,
    sign_json,
    verify_json_signature,
    get_signature_info,
    Gene1799Signer,
    Gene1799Certificate
)

__version__ = "1.0.0"
__author__ = "Gene1799 Art Corporation"
__license__ = "16/L4090879L"

__all__ = [
    'signer',
    'sign_json',
    'verify_json_signature',
    'get_signature_info',
    'Gene1799Signer',
    'Gene1799Certificate'
]
