# Sync-HaloESETMSP
Sync ESET MSP license counts to HaloPSA for a more accurate billing experience.

# Usage
From the ESET MSP portal, select a customer. Edit the custom identifier with their Halo ID in the format HALOCUSTOMER:123 where 123 is the Halo Client ID.
If the license is assigned to a site rather than the customer, use the format of HALOSITE:456 where 456 is the Halo Site ID.

Insert your credentials into the `Connect-HaloAPI` and `Connect-ESETAPI` and run.
