# Swift client for ZetaPush

[![Version](https://img.shields.io/cocoapods/v/ZetaPushSwift.svg?style=flat)](http://cocoapods.org/pods/ZetaPushSwift)
[![License](https://img.shields.io/cocoapods/l/ZetaPushSwift.svg?style=flat)](http://cocoapods.org/pods/ZetaPushSwift)
[![Platform](https://img.shields.io/cocoapods/p/ZetaPushSwift.svg?style=flat)](http://cocoapods.org/pods/ZetaPushSwift)

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

You must have [Cocoapods](https://cocoapods.org/) installed and running

```
sudo gem install cocoapods
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

You can read the [full documentation](https://doc.zetapush.com/how/introduction/) for more information

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

To verify that you're really connected, let's add a callback to be warned when the connection is established.

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

To summarize, when you send a message to ZetaPush (Publish), you get the response only if you've have previously asked for it (Subscribe).

For the Echo service, you publish a message on the verb "echo" and you get the response on the verb "echo". The [reference site](https://ref.zpush.io/#it_echo) describe all the verb you can publish and the corresponding subscription verb.

Back to the code !

```swift
import UIKit
import ZetaPushSwift

class ViewController: UIViewController {

    let zetaPushWeakClient:ZetaPushWeakClient = ZetaPushWeakClient(sandboxId: "YOUR_SANDBOX_ID", weakDeploymentId: "YOUR_WEAK_DEPLOYMENT_ID")
    
    // Declare a new service
    var zetaPushServiceEcho : ZetaPushService?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Callback fired when a successful handshake occurs
        zetaPushWeakClient.onSuccessfulHandshake = onSuccessfulHandshake

        // Create an echo service with the corresponding DeploymentId
        zetaPushServiceEcho = ZetaPushService(zetaPushWeakClient, deploymentId: "YOUR_ECHO_DEPLOYMENT_ID")

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
    }

    // Just call the echo service when we click on a button
    @IBAction func OnMyFirstTestDown(_ sender: Any) {
        zetaPushServiceEcho?.publish(verb: "echo", parameters: ["hello": "world" as NSObject])
    }

}

```

That's it, you've called your fist ZetaPush service.

Remenber that a lot of services are available right out of the box on ZetaPush. You can view a full description on our [reference website](https://ref.zpush.io)

## Much more power with Macros 

### ZMS overview

You can read an overview of ZMS (ZetaPush Macro Scripts) on our [documentation website](https://doc.zetapush.com/how/zms-language/introduction/)

You can also follow the [QuickStart](https://doc.zetapush.com/quickstart/) to install the minimum software to create your first macro.

### Our first macro

Les create a simple macro with Eclipe. This macro is the default one when you create a new project (with a return on channel __selfName).

```
/**
* Takes a message as input, and returns it, with a server message
*/
macroscript welcome(/** message from the client */ string message = "Hello") {
	// ...
} return {clientMessage : message, serverMessage : WELCOME_MESSAGE} on channel __selfName

```

Now, let's call it in our iOS project. There's two way to call a macro: with a publish-subscribe style or with a promise.

### Call a macro with Publish-Subscribe

Back to code !

```swift
import UIKit
import ZetaPushSwift

class ViewController: UIViewController {

    let zetaPushWeakClient:ZetaPushWeakClient = ZetaPushWeakClient(sandboxId: "YOUR_SANDBOX_ID", weakDeploymentId: "YOUR_WEAK_DEPLOYMENT_ID")

    // Declare a new Macro Service
    var zetaPushMacroService: ZetaPushMacroService?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Callback fired when a successful handshake occurs
        zetaPushWeakClient.onSuccessfulHandshake = onSuccessfulHandshake

        // Create a new Macro Service (with default deployementId: "macro_0")
        zetaPushMacroService = ZetaPushMacroService(zetaPushWeakClient)

        // Subscribe to the welcome verb
        _ = zetaPushMacroService?.subscribe(verb: "welcome", block: { (messageDic) in
            print("ViewController zetaPushMacroService?.subscribe", messageDic)
        })

        // Connect to ZetaPush
        zetaPushWeakClient.connect()
    }

    func onSuccessfulHandshake(_ client:ClientHelper){
        // The connection to ZetaPush is a success
        print("ViewController SuccessfulHandshake")
    }

    // Just call the macro service when we click on a button
    @IBAction func OnMyFirstTestDown(_ sender: Any) {
        zetaPushMacroService?.call(verb: "welcome", parameters: ["message": "hello world" as NSObject])
    }

}
```

### Call a macro with a promise

Promise a really usefull in asynchronious macro call. For more information you can read more about promise on [wikipedia](https://en.wikipedia.org/wiki/Futures_and_promises)

With ZetaPush IOs SDK, you can call a macro in a "nearly" synchronous way thanks to promises. 

```swift
import UIKit
import ZetaPushSwift

class ViewController: UIViewController {

    let zetaPushWeakClient:ZetaPushWeakClient = ZetaPushWeakClient(sandboxId: "YOUR_SANDBOX_ID", weakDeploymentId: "YOUR_WEAK_DEPLOYMENT_ID")

    // Declare a new Macro Service
    var zetaPushMacroService: ZetaPushMacroService?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Callback fired when a successful handshake occurs
        zetaPushWeakClient.onSuccessfulHandshake = onSuccessfulHandshake

        // Create a new Macro Service (with default deployementId: "macro_0")
        zetaPushMacroService = ZetaPushMacroService(zetaPushWeakClient)

        // Connect to ZetaPush
        zetaPushWeakClient.connect()
    }

    func onSuccessfulHandshake(_ client:ClientHelper){
        // The connection to ZetaPush is a success
        print("ViewController SuccessfulHandshake")
    }

    // Just call the macro service when we click on a button
    @IBAction func OnMyFirstTestDown(_ sender: Any) {
        zetaPushMacroService?.call(verb: "welcome", parameters: ["message": "hello world" as NSObject])
            .then{ result in
               print ("call result", result)
            }
            .catch { error in
                print ("call error", error)
            }
    }

}
```

That's it, you are able to call a service and a macro from ZetaPush. 

## Auto-generated code with ZetaPush CLI

With ZetaPush command line, you can generate a swift code based on zms language. This generated code will give you everything you need to use your macors.

This generated code will create 4 files:

### Structure file

In this file, you will get all the structures (classes) needed to call your macro: the input classes, the output clases and the completion classes.

### Async API

In this file, a class is generated with all the methods needed to call the macros.

### Promise API

In this file, a class is generated with all the methods needed to call the macros. The main difference between the Async API is that the methods return a promise.

### AsyncAPIListener

In this file, a class is generated with all the method needed to listen to the result of the macros.

## How to use auto-generated code

### Create a class that inherit from AsyncAPIListener

In this class, you will override the methods that fits your needs.
```swift
open class MyAPIListener: MacrosAsyncApiListener{
    // Only override the method i'm interesting in
    open override func sendMessage(_ parameter: sendMessageCompletion){
        print("sendMessage")
    }
```

When you will create a MyAPIListener object, the sendMessage function will be called each time the corresponding macro is called.

### Use the AsyncApi or PromiseAPI objects

```swift
// Create the objects with a ZetaPushClient parameter
	webRTCAsyncApi = WebRTCAsyncApi(zetaPushClient)
        webRTCPromiseApi = WebRTCPromiseApi(zetaPushClient)
	
	//To call a promise API
	
	webRTCPromiseApi?.createPublicRoom(parameters: _createPublicRoomInput)
            .then { result -> Void in
                
                print ("createPublicRoom", result.result.room!)
                
            }
            .catch { error in
                print ("createPublicRoom error", error)
        }
	
	// To call the same api with the asyncAPI
	webRTCAsyncApi?.createPublicRoom(parameters: _createPublicRoomInput)
	// The result will be returned to the AsyncAPIListener
	
```
