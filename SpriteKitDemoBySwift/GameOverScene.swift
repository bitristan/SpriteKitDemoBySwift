//
//  GameScene.swift
//  SpriteKitDemoBySwift
//
//  Created by Ting Sun on 7/29/14.
//  Copyright (c) 2014 Tinker S. All rights reserved.
//

import SpriteKit

class GameOverScene: SKScene, SKPhysicsContactDelegate {
    
    var won: Bool = false
    
    init(size: CGSize, won: Bool) {
        super.init(size: size)
        self.won = won
    }

    override func didMoveToView(view: SKView) {
        let myLabel = SKLabelNode(fontNamed:"Chalkduster")
        if self.won {
            myLabel.text = "You Win!!!"
        } else {
            myLabel.text = "You Lose!!!"
        }
        myLabel.fontSize = 80
        myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame))
        self.addChild(myLabel)
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        let reveal = SKTransition.flipHorizontalWithDuration(0.5)
        let gameScene = GameScene(size: self.size)
        self.view.presentScene(gameScene, transition: reveal)
    }
    
    override func update(currentTime: CFTimeInterval) {
    }
    
}
