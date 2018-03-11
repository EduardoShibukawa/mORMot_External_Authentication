"""
Author: Eduardo Shibukawa

This module contais the session class of a mORMot server
"""
import time
import binascii

from utils_duh import to_hex8_str


class Session:
    """
    Class Session is used to store values of a mORMot session.

    Attributes:
        private_salt (str): The response key when logging in a mORMot server.
        id (str): Session id, it's  the value before the character '+' of the private salt string.
        id_hex (str): Hexadecimal value of the session id.
        private_salt_hash (str): It's the salt value used when generating the "session_signature",
        its calculated as:
            - crc32(password_hash, crc32(private_salt))

        tick_count_offset (Session): The tick count of the login moment
    """

    def __init__(self, salt, password_hash):
        self.private_salt = salt
        self.id = salt.split('+')[0]
        self.id_hex = to_hex8_str(int(self.id))
        self.private_salt_hash = binascii.crc32(self.private_salt.encode())
        self.private_salt_hash = binascii.crc32(password_hash.encode(),
                                                self.private_salt_hash)
        self.tick_count_offset = self.get_tick_count()

    @staticmethod
    def get_tick_count():
        """
        Simulates the GetTickCount64 of windows
        Returns:
            Current tick count
        """
        return int(time.monotonic() * 1e+3)