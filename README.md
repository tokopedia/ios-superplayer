<p align="center">
<img src="https://user-images.githubusercontent.com/17944191/136305807-313ba19d-2b7e-464d-b136-c671d4431694.png" alt="SuperPlayer" title="SuperPlayer" width="300"/>
</p>

SuperPlayer is a library to wrap AVPlayer with Composable Architecture. It can be used in SwiftUI and UIKit.

* [Learn more](#learn-more)
* [What is the Composable Architecture?](#what-is-the-composable-architecture)
* [Example](#example)
* [Basic usage](#basic-usage)
* [Data Flow](#data-flow)
* [Requirements](#requirements)
* [Installation](#installation)
* [Credits and thanks](#credits-and-thanks)


## Learn More

AVPlayer a controller object used to manage the playback and timing of a media asset. You can use an AVPlayer to play local and remote file-based media, such as QuickTime movies and MP3 audio files, as well as audiovisual media served using HTTP Live Streaming.

This SuperPlayer is composing AVPlayer to a TCA component. All state of the player is handled by SuperPlayer, and you just need to listen it to your controller, view, or other wrapper.

## What is the Composable Architecture?

The Composable Architecture (TCA, for short), is a library for building applications in a consistent and understandable way, with composition, testing, and ergonomics in mind. It can be used in SwiftUI, UIKit, and more, and on any Apple platform (iOS, macOS, tvOS, and watchOS). You can learn more about composable architecture from this [repository](https://github.com/pointfreeco/swift-composable-architecture)


## Example

@alvin.pratama made a tutorial of how to try this Superplayer on this [medium](https://alvinmatthew.medium.com/db2de75ed2fd)

## Basic Usage

Let’s say we will play the video from this link http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4

Open Your ViewController, and import `ComposableArchitecture` and `SuperPlayer`

```swift
import ComposableArchitecture
import SuperPlayer
```


Create a function called handleVideo() , we will handle video setup in this function.

```swift
func handleVideo() {
    // 1
    let store = Store<SuperPlayerState, SuperPlayerAction>(initialState: SuperPlayerState(), reducer: superPlayerReducer, environment: SuperPlayerEnvironment.live())
    let superPlayer = SuperPlayerViewController(store: store)

    // 2
    superPlayer.view.frame = view.bounds
    superPlayer.view.backgroundColor = .black
    addChild(superPlayer)
    view.addSubview(superPlayer.view)
    superPlayer.didMove(toParent: self)

    // 3
    let viewStore = ViewStore(store)
    viewStore.send(.load(URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!, autoPlay: true))
}
```

1. SuperPlayerViewController will act as the intermediate object that performs the actual subscription to both store and the AVFoundation playback states. SuperPlayerViewController has AVPlayerLayer as its sublayer to display the video from AVPlayer.
2. Constructing view for SuperPlayerViewController
3. Send the action to load the video.

Call this function inside viewDidLoad before any view setup made.


SuperPlayer is supposed to working with TCA, so why not create our TCA state management to play the video. Create Reducer.swift file for your controller

```swift
import Foundation
import ComposableArchitecture
import SuperPlayer // 1
// 2
struct AppState: Equatable {
    var superPlayerState: SuperPlayerState = .init()
}

enum AppAction: Equatable {
    case loadVideo
    case handlePausePlayVideo
    
    case superPlayerAction(SuperPlayerAction)
}

// 3
struct AppEnvironment {
    var getVideoURLString: () -> String
    
    static var mock = AppEnvironment(
        getVideoURLString: {
            "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        }
    )
}

// 4
let appReducer: Reducer<AppState, AppAction, AppEnvironment> = .combine(
    superPlayerReducer
        .pullback(
            state: \.superPlayerState,
            action: /AppAction.superPlayerAction,
            environment: { _ in SuperPlayerEnvironment.live() }
        ),
    Reducer { state, action, env in
        switch action {
        case .loadVideo:
            return Effect(value: .superPlayerAction(.load(URL(string: env.getVideoURLString())!, autoPlay: true)))
            
        default:
            return .none
        }
    }
)
```

1. Import SuperPlayer
2. Add `SuperPlayerState` and `SuperPlayerAction` to pullback `SuperPlayerReducer`. `loadVideo` action will act as a trigger to load the video when we call it from ViewController later.
3. Usually, the environment is used for producing Effects such as API clients, analytics clients, etc. For this case let’s directly return the video URL we want to play.
4. Combine appReducer and superPlayerReducer to merge all the effects. We create a pullback to transforms superPlayerReducer into state management that works on global state management.


Go back to your view controller file and set up the store.

```swift
// 1
let store = Store(
    initialState: AppState(),
    reducer: appReducer,
    environment: AppEnvironment.mock
)
lazy var viewStore = ViewStore(self.store)

override func viewDidLoad() {
    super.viewDidLoad()
    
    // 2
    handleVideo(store: store.scope(
        state: \.superPlayerState,
        action: AppAction.superPlayerAction
    ))

    setupView()
    
    // 3
    viewStore.send(.loadVideo)
}

func handleVideo(store: Store<SuperPlayerState, SuperPlayerAction>) {
    // 4
    let superPlayer = SuperPlayerViewController(store: store)
    superPlayer.view.frame = view.frame
    superPlayer.view.backgroundColor = .black

    addChild(superPlayer)
    view.addSubview(superPlayer.view)
    superPlayer.didMove(toParent: self)
}
```

1. Setup store and viewStore to pass states as objects to interact with view.
2. Scope to transform a store into SuperPlayer’s store that deals with local state and actions.
3. Send loadVideo action load the video.
4. Update SuperPlayerViewController parameter to use the store that was scoped before.

Build the project, and it will show you the video player with url we provide to environment. Now we can play video without setting up many AVPlayer states.

## Data Flow

![1_63q5BLtn9DCl6fQcjfpMrw](https://user-images.githubusercontent.com/17944191/136305965-f41a647b-1055-46fd-b0d4-8aae257694a4.png)


## Requirements

The SuperPlayer depends on the Combine framework and ComposableArchitecture, so it requires minimum deployment targets of iOS 13

## Installation

You can add SuperPlayer to an Xcode project by adding it as a package dependency.

  1. From the **File** menu, select **Swift Packages › Add Package Dependency…**
  2. Enter `https://github.com/tokopedia/ios-superplayer` into the package repository URL text field
  3. Depending on how your project is structured:
      - If you have a single application target that needs access to the library, then add **SuperPlayer** directly to your application.
      - If you want to use this library from multiple Xcode targets, or mixing Xcode targets and SPM targets, you must create a shared framework that depends on **SuperPlayer** and then depend on that framework in all of your targets.

## Help

If you want to discuss the SuperPlayer or have a question about how to use it to solve your video player problem, you can start a topic in the [discussions](https://github.com/tokopedia/ios-superplayer/discussions) tab of this repo


## Credits and thanks

These following people is working hard to craft this lovely player and its documentations to make what SuperPlayer is today: 

Adityo Rancaka, Alvin Matthew Pratama, and many of iOS Superman, and iOS Tokopedia Team ❤️
    

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
