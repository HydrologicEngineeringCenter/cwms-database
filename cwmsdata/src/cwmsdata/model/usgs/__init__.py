"""
USGS module
"""

from urllib.parse import urlunsplit, urlencode

services = {
    "scheme": "https",
    "root": "waterservices.usgs.gov",
    "instantaneous": "iv",
    "site": "site",
    "daily": "dv",
}

output_format = {
    "waterml": "waterml,2.0",
    "rdb-tab": "rdb",
    "rdb": "rdb,1.0",
    "json": "json",
}


def usgs_services_url(service: str, query: dict = {}, fragment: str = None):
    """
    Define USGS REST services

    Parameters
    ----------
    service : str
        reference https://waterservices.usgs.gov/rest/
    query : dict, optional
        url query, by default {}
    fragment : str, optional
        usr fragment, by default None

    Returns
    -------
    str
        USGS url web service
    """
    if service not in services:
        return None

    query["siteStatus"] = "all"

    q = urlencode(query)
    url = urlunsplit(
        (
            services["scheme"],
            services["root"],
            f"/nwis/{services[service]}/",
            q,
            fragment,
        )
    )

    return url
