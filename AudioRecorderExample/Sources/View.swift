//
//  View.swift
//  AudioRecorderExample
//
//  Created by Clay on 5/25/17.
//  Copyright © 2017 Clay Ellis. All rights reserved.
//

import UIKit

class View: UIView {
    
    let button = UIButton()
    
    init() {
        super.init(frame: .zero)
        configureSubviews()
        configureLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func configureSubviews() {
        backgroundColor = .white
        
        button.setTitle("Launch Recorder", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.setTitleColor(UIColor.black.withAlphaComponent(0.4), for: .highlighted)
    }
    
    fileprivate func configureLayout() {
        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
    }
        
}
