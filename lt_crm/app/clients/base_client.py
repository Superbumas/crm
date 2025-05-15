"""Base API client for external integrations."""
import logging
from typing import Dict, List, Optional, Any, Union
import httpx
from ..exceptions import APIClientError, APIConnectionError, APITimeoutError


class BaseAPIClient:
    """Base API client for all external integrations."""
    
    def __init__(self, base_url: str, timeout: int = 30):
        """
        Initialize the base API client.
        
        Args:
            base_url (str): API base URL
            timeout (int): Request timeout in seconds
        """
        self.base_url = base_url
        self.timeout = timeout
        self.logger = logging.getLogger(f"{__name__}.{self.__class__.__name__}")
    
    def _get_headers(self) -> Dict[str, str]:
        """
        Get request headers. Override in subclasses if needed.
        
        Returns:
            Dict[str, str]: Headers dictionary
        """
        return {
            "Content-Type": "application/json",
            "Accept": "application/json"
        }
    
    async def _request(
        self,
        method: str,
        endpoint: str,
        params: Optional[Dict[str, Any]] = None,
        data: Optional[Dict[str, Any]] = None,
        json_data: Optional[Dict[str, Any]] = None,
        headers: Optional[Dict[str, str]] = None,
    ) -> Dict[str, Any]:
        """
        Make an async HTTP request.
        
        Args:
            method (str): HTTP method (GET, POST, etc.)
            endpoint (str): API endpoint
            params (Dict[str, Any], optional): Query parameters
            data (Dict[str, Any], optional): Form data
            json_data (Dict[str, Any], optional): JSON data
            headers (Dict[str, str], optional): Additional headers
            
        Returns:
            Dict[str, Any]: Response data
            
        Raises:
            APIConnectionError: On connection errors
            APITimeoutError: On timeout errors
            APIClientError: On API errors
        """
        url = f"{self.base_url.rstrip('/')}/{endpoint.lstrip('/')}"
        request_headers = self._get_headers()
        if headers:
            request_headers.update(headers)
            
        self.logger.debug(f"Making {method} request to {url}")
        
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.request(
                    method=method,
                    url=url,
                    params=params,
                    data=data,
                    json=json_data,
                    headers=request_headers
                )
                
                response.raise_for_status()
                return response.json()
        except httpx.ConnectError as e:
            self.logger.error(f"Connection error: {str(e)}")
            raise APIConnectionError(f"Failed to connect to {url}: {str(e)}")
        except httpx.TimeoutException as e:
            self.logger.error(f"Request timed out: {str(e)}")
            raise APITimeoutError(f"Request to {url} timed out after {self.timeout}s")
        except httpx.HTTPStatusError as e:
            self.logger.error(f"HTTP error {response.status_code}: {response.text}")
            raise APIClientError(f"API error {response.status_code}: {response.text}")
        except Exception as e:
            self.logger.error(f"Unexpected error: {str(e)}")
            raise APIClientError(f"Unexpected error: {str(e)}")
    
    def request(
        self,
        method: str,
        endpoint: str,
        params: Optional[Dict[str, Any]] = None,
        data: Optional[Dict[str, Any]] = None,
        json_data: Optional[Dict[str, Any]] = None,
        headers: Optional[Dict[str, str]] = None,
    ) -> Dict[str, Any]:
        """
        Make a synchronous HTTP request.
        
        Args:
            method (str): HTTP method (GET, POST, etc.)
            endpoint (str): API endpoint
            params (Dict[str, Any], optional): Query parameters
            data (Dict[str, Any], optional): Form data
            json_data (Dict[str, Any], optional): JSON data
            headers (Dict[str, str], optional): Additional headers
            
        Returns:
            Dict[str, Any]: Response data
            
        Raises:
            APIConnectionError: On connection errors
            APITimeoutError: On timeout errors
            APIClientError: On API errors
        """
        url = f"{self.base_url.rstrip('/')}/{endpoint.lstrip('/')}"
        request_headers = self._get_headers()
        if headers:
            request_headers.update(headers)
            
        self.logger.debug(f"Making {method} request to {url}")
        
        try:
            with httpx.Client(timeout=self.timeout) as client:
                response = client.request(
                    method=method,
                    url=url,
                    params=params,
                    data=data,
                    json=json_data,
                    headers=request_headers
                )
                
                response.raise_for_status()
                return response.json()
        except httpx.ConnectError as e:
            self.logger.error(f"Connection error: {str(e)}")
            raise APIConnectionError(f"Failed to connect to {url}: {str(e)}")
        except httpx.TimeoutException as e:
            self.logger.error(f"Request timed out: {str(e)}")
            raise APITimeoutError(f"Request to {url} timed out after {self.timeout}s")
        except httpx.HTTPStatusError as e:
            self.logger.error(f"HTTP error {response.status_code}: {response.text}")
            raise APIClientError(f"API error {response.status_code}: {response.text}")
        except Exception as e:
            self.logger.error(f"Unexpected error: {str(e)}")
            raise APIClientError(f"Unexpected error: {str(e)}")
            
    def get(self, endpoint: str, params: Optional[Dict[str, Any]] = None, headers: Optional[Dict[str, str]] = None) -> Dict[str, Any]:
        """Perform GET request."""
        return self.request("GET", endpoint, params=params, headers=headers)
        
    def post(self, endpoint: str, json_data: Optional[Dict[str, Any]] = None, headers: Optional[Dict[str, str]] = None) -> Dict[str, Any]:
        """Perform POST request with JSON data."""
        return self.request("POST", endpoint, json_data=json_data, headers=headers)
        
    def put(self, endpoint: str, json_data: Optional[Dict[str, Any]] = None, headers: Optional[Dict[str, str]] = None) -> Dict[str, Any]:
        """Perform PUT request with JSON data."""
        return self.request("PUT", endpoint, json_data=json_data, headers=headers)
        
    def delete(self, endpoint: str, params: Optional[Dict[str, Any]] = None, headers: Optional[Dict[str, str]] = None) -> Dict[str, Any]:
        """Perform DELETE request."""
        return self.request("DELETE", endpoint, params=params, headers=headers) 