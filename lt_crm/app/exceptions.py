"""Custom exceptions for the application."""


class APIError(Exception):
    """Base exception for all API errors."""
    pass


class APIClientError(APIError):
    """Exception raised for API client errors (4xx)."""
    pass


class APIServerError(APIError):
    """Exception raised for API server errors (5xx)."""
    pass


class APIConnectionError(APIError):
    """Exception raised for API connection errors."""
    pass


class APITimeoutError(APIError):
    """Exception raised for API timeout errors."""
    pass


class APIRateLimitError(APIError):
    """Exception raised when API rate limit is exceeded."""
    pass 