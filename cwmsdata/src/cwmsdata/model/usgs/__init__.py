"""_summary_
"""

from urllib.parse import urlunsplit, urlencode

services={
    "scheme": "https",
    "root": "waterservices.usgs.gov",
    "instantaneous":"iv",
    "site":"site",
    "daily":"dv",
}

output_format = {
    "waterml": "waterml,2.0",
    "rdb-tab": "rdb", 
    "rdb": "rdb,1.0",
    "json": "json"
}

def usgs_services_url(service: str, query: dict={}, fragment: str=None):
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
