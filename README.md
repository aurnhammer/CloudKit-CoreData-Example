# CloudKit-CoreData-Example
An example of how to use CloudKit and Core Data together with bi-directional sync across a user's devices. The Example App contains a database of iBeacons that can be placed on a map and simulate broadcasting.

# Installation
Clone the respository.

Note: This example is already connected to a Database and has existing sample data. If you choose to use your own Cloudkit Database you will need to change the Bundle Identifier to an account you have control over. Since this will be an empty database you will need to create the appropriate Records and Fields. This example defines a "Beacon" and "Place" record and a query index on "RecordName"

# Creating Beacons
From the List choose the "+" button which will bring you to the Beacon Detail. Here you can give the Beacon a name, its Major and Minor values, and Accuracy Threshold (which filters out Beacons beyone the threshold) and its Location (set by placing a pin on a map). The Enabled button will emulate broadcasting an iBeacon signal.

Run the app on more than one device. Enable an iBeacon simulation from the Detail View using the "Enabled" button. The Ranging Tab shows the iBeacons that have been detected. If you have multiple devices simulating iBeacons they will appear in the list sorted by distance.

Play around with positioning the beacons changing their names and adding new ones. Depending on your connection the changes should be reflected fairly quickly on the other device. If a device is offline (for example airplane mode) the changes will reflect one the device comes back online.


