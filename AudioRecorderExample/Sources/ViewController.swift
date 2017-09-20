//
//  ViewController.swift
//  AudioRecorderExample
//
//  Created by Clay on 5/25/17.
//  Copyright © 2017 Clay Ellis. All rights reserved.
//

import UIKit
import AudioRecorder

class ViewController: UIViewController {

    let contentView = View()
    
    override func loadView() {
        view = contentView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.button.addTarget(self, action: #selector(buttonTapped(sender:)), for: .touchUpInside)
    }
    
    @objc func buttonTapped(sender: UIButton) {
        let audioRecorder = AudioRecorderController()
        audioRecorder.delegate = self
        present(audioRecorder, animated: true, completion: nil)
    }

}

extension ViewController: AudioRecorderControllerDelegate {

    func audioRecorderControllerDidCancel(_ recorder: AudioRecorderController) {
        recorder.dismiss(animated: true, completion: nil)
    }

    func audioRecorderController(_ recorder: AudioRecorderController, didFinishRecordingAudioWithURL audioURL: URL) {
        recorder.dismiss(animated: true, completion: nil)
        print(audioURL.path)
    }

}
