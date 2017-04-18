# Swift client for ZetaPush


## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

You must have [Cocoapods](https://cocoapods.org/) installed and running

```
gem install cocoapods
```

### Installing

First create a new project with XCode.
In the project directory launch the command

```cmd
pod init
```

A PodFile is created, edit it and add ZetaPushSwift pod

```
# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'ZetaPushTestPod' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for ZetaPushTestPod
  pod "ZetaPushSwift"

end

```

Finally, run pod install to install libraries

```cmd
pod install

```

You can now open the newly generated workspace (.xcworkspace) in XCode

WARNING ! Close the previously openned project and open the workspace instead

### Pre-requisit

You must have an account on [ZetaPush](https://zetapush.com) and a valid SandboxId. FYI, on ZetaPush a SandboxId identify your hosted application on ZetaPush cloud.

For the examples above, you must have deployed an authentication ( [Weak](https://ref.zpush.io/#it_weak) at least) and an [Echo](https://ref.zpush.io/#it_echo) service

You can read the [full documentation](https://doc.zetapush.com/how/introduction/) for further information

## Code your first client

### Connecting to ZetaPush

You must import the library into your swift file
```swift
import ZetaPushSwift 

```

Create a ZetaPushWeakClient object. This object will do all the hard work for you to connect to ZetaPush with a weak authentication

```swift
import UIKit
import ZetaPushSwift

class ViewController: UIViewController {

    let zetaPushWeakClient:ZetaPushWeakClient = ZetaPushWeakClient(sandboxId: "YOUR_SANDBOX_ID", weakDeploymentId: "YOUR_WEAK_DEPLOYMENT_ID")

    override func viewDidLoad() {
        super.viewDidLoad()

        // Connect to ZetaPush
        zetaPushWeakClient.connect()
    }
}

```

That's it. You're connected!

To verify that you're really connected, let's add a callback to be warn when the connection is established.

```swift
import UIKit
import ZetaPushSwift

class ViewController: UIViewController {

    let zetaPushWeakClient:ZetaPushWeakClient = ZetaPushWeakClient(sandboxId: "YOUR_SANDBOX_ID", weakDeploymentId: "YOUR_WEAK_DEPLOYMENT_ID")

    override func viewDidLoad() {
        super.viewDidLoad()

        // 
        zetaPushWeakClient.onSuccessfulHandshake = onSuccessfulHandshake

        // Connect to ZetaPush
        zetaPushWeakClient.connect()
    }

    func onSuccessfulHandshake(_ client:ClientHelper){
        // The connection to ZetaPush is a success
        print("ViewController SuccessfulHandshake")
    }
}

```

### Call your first service

Now we can call a useless Echo Service that will "echo" ie send back everything we send to him.

If you're not familiar with the publish-subscribe paradigm, you can get more information on our [documentation website](https://doc.zetapush.com/how/principles/)

To summarize, when you send a message to ZetaPush (Publish), you get the response only if you've have previously asked for if (Subscribe).

For the Echo service, you publish a message on the verb "echo" and you get the response on the verb "echo". The [reference site](https://ref.zpush.io/#it_echo) describe all the verb you can publish and the corresponding subscription verb.

Back to the code !

```swift
import UIKit
import ZetaPushSwift

class ViewController: UIViewController {

    let zetaPushWeakClient:ZetaPushWeakClient = ZetaPushWeakClient(sandboxId: "YOUR_SANDBOX_ID", weakDeploymentId: "YOUR_WEAK_DEPLOYMENT_ID")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create an echo service with the corresponding DeploymentId
        zetaPushServiceEcho = ZetaPushService(zetaPushWeakClient, deploymentId: "pQSH")

        // Subscribe to the echo verb
        _ = zetaPushServiceEcho?.subscribe(verb: "echo", block: { (messageDict) in
            print("ViewController zetaPushServiceEcho?.subscribe", messageDict)
        })

        // Connect to ZetaPush
        zetaPushWeakClient.connect()
    }

    func onSuccessfulHandshake(_ client:ClientHelper){
        // The connection to ZetaPush is a success
        print("ViewController SuccessfulHandshake")
        
        // Let's call our Echo service
        zetaPushServiceEcho?.publish(verb: "echo", parameters: ["message": "Hello World" as NSObject])
    }

}

```

That's it, you've called your fist ZetaPush service


