"""
Package logger
"""

import logging

class package_logger(logging.Logger):
    """Package logger extending logging.Logger

    Parameters
    ----------
    logging : Logger
        Logger object
    """
    def __init__(self):
        super().__init__(__package__)

        self.log_level = "info"

        formatter = logging.Formatter(
            "[%(asctime)s.%(msecs)03d] "
            + "{%(name)s:%(funcName)s} - %(levelname)-s - %(message)s",
            "%Y-%m-%dT%H:%M:%S",
        )

        ch = logging.StreamHandler()

        ch.setFormatter(formatter)
        self.addHandler(ch)

    @property
    def log_level(self):
        return logging._levelToName[self.level]

    @log_level.setter
    def log_level(self, level):
        level = logging._nameToLevel[level.upper()] if isinstance(level, str) else level
        self.setLevel(level)


# create a logger for the package and set the logging level from env vars
logger = package_logger()
logger.log_level = "DEBUG"
