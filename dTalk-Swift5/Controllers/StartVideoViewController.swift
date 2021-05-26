//
//  StartVideoViewController.swift
//  dTalk-Swift5
//
//  Created by Sparsh Singh on 30/04/21.
//

import UIKit
import AVKit

class StartVideoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //validateAuth()
        
    }
    
    var player: AVPlayer?
    
    private func loadVideo() {

        //this line is important to prevent background music stop
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient)
        } catch { }

        let path = Bundle.main.path(forResource: "pre-comp 1", ofType:"mp4")

        player = AVPlayer(url: NSURL(fileURLWithPath: path!) as URL)
        let playerLayer = AVPlayerLayer(player: player)

        playerLayer.frame = self.view.frame
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        playerLayer.zPosition = -1

        self.view.layer.addSublayer(playerLayer)

        player?.seek(to: CMTime.zero)
        player?.play()
    }

}
