"""
Author: Eduardo Shibukawa

This module contais hex conversion function
"""

def to_hex_str(value):
    """
        Convert the value to a Hexadecimal string value.

        Args:
            value (any): any value.

        Returns:
            Hexadecimal string of the value
    """
    return hex(value).lstrip('0x').upper()

def to_hex8_str(value):
    """
        Convert the value to a Hexadecimal string value.

        Args:
            value (any): any value.

        Returns:
            Hexadecimal string of the value with length 8
    """
    hex8 = to_hex_str(value).zfill(8)
    if len(hex8) > 8:
        hex8 = hex8.slice(len(hex8) - 8)
    return hex8