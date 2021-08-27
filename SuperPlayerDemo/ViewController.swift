//
//  ViewController.swift
//  SuperPlayer
//
//  Created by Andrey Yoshua on 04/08/21.
//

import ComposableArchitecture
import SuperPlayer
import SwiftUI
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let store = Store<SuperPlayerState, SuperPlayerAction>(initialState: SuperPlayerState(), reducer: superPlayerReducer, environment: SuperPlayerEnvironment.live())
        let superPlayer = SuperPlayerViewController(store: store)
        addChild(superPlayer)
        view.addSubview(superPlayer.view)
        superPlayer.view.frame = view.bounds
        superPlayer.didMove(toParent: self)
        
        let viewStore = ViewStore(store)
        viewStore.send(.load(URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!, autoPlay: true))
        
        let debugView = SuperPlayerDebugView(store: store)
        view.addSubview(debugView)
        debugView.frame = view.bounds
    }
}



struct ViewController_Previews: PreviewProvider {
  static var previews: some View {
    let vc = UINavigationController(
        rootViewController: ViewController()
    )
    return UIViewRepresented(makeUIView: { _ in vc.view })
  }
}
