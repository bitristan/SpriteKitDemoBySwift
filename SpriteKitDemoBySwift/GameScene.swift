//
//  GameScene.swift
//  SpriteKitDemoBySwift
//
//  Created by Ting Sun on 7/29/14.
//  Copyright (c) 2014 Tinker S. All rights reserved.
//

import SpriteKit
import AVFoundation


class GameScene: SKScene, SKPhysicsContactDelegate {
    var lastSpawnTimeInterval: CFTimeInterval = 0.0
    var lastUpdateTimeInterval: CFTimeInterval = 0.0

    var player: SKSpriteNode!
    var backgroundMusicPlayer: AVAudioPlayer!

    // win if hit more than 20 monsters
    var monsterDestroyed = 0
    
    // lose if more than 5 monsters escaped
    var monsterEscaped = 0
    
    let projectileCategory: UInt32 = 1 << 0
    let monsterCategory: UInt32 = 1 << 1
    
    init(coder aDecoder: NSCoder!) {
        super.init(coder: aDecoder)
    }

    init(size: CGSize) {
        super.init(size: size)
    }
    
    override func didMoveToView(view: SKView) {

        /* Setup your scene here */
        let myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "Hello, World!"
        myLabel.fontSize = 65
        myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame))
        
        self.backgroundColor = SKColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)

        player = SKSpriteNode(imageNamed: "player");
        player.position = CGPoint(x: 100, y: 100)

        self.addChild(myLabel)
        self.addChild(player)
        
        self.physicsWorld.gravity = CGVector(0, 0)
        self.physicsWorld.contactDelegate = self
        
        self.backgroundMusicPlayer = AVAudioPlayer(contentsOfURL: NSBundle.mainBundle().URLForResource("background-music-aac", withExtension: "caf"), error: nil)
        self.backgroundMusicPlayer.numberOfLoops = 1
        self.backgroundMusicPlayer.prepareToPlay()
        self.backgroundMusicPlayer.play()
    }
    
    func addMonster() {
        let monster = SKSpriteNode(imageNamed: "monster")
        let minY = monster.size.height / 2
        let maxY = self.frame.size.height - monster.size.height / 2
        let rangeY = maxY - minY
        let actualY: Double = Double(arc4random() % UInt32(rangeY)) + minY
        monster.position = CGPoint(x: self.frame.size.width / 2 + monster.size.width / 2, y: actualY)
        addChild(monster)
        
        let minDuration = 2.0
        let maxDuration = 4.0
        let rangeDuration = maxDuration - minDuration
        let actualDuration = Double(arc4random() % UInt32(rangeDuration)) + minDuration
        
        let actionMove: SKAction = SKAction.moveTo(CGPoint(x: -monster.size.width / 2, y: actualY), duration: actualDuration)
        //let actionMoveDone: SKAction = SKAction.removeFromParent()
        let actionMoveDone = SKAction.runBlock({
                self.monsterEscaped++
                if self.monsterEscaped > 5 {
                    let reveal = SKTransition.flipHorizontalWithDuration(0.5)
                    let gameOverScene = GameOverScene(size: self.size, won: false)
                    self.view.presentScene(gameOverScene, transition: reveal)
                }
            })
        monster.runAction(SKAction.sequence([actionMove, actionMoveDone]))
        
        //为怪物sprite 创建物理外形。在这里，这个外形被定义成和怪物sprite大小一致的矩形，与怪物自身大致相匹配
        monster.physicsBody = SKPhysicsBody(rectangleOfSize: monster.size)
        //将怪物物理外形的dynamic（动态）属性置为YES。这表示怪物的移动不会被物理引擎所控制。你可以在这里不受影响而继续使用之前的代码（指之前怪物的移动action）
        monster.physicsBody.dynamic = true
        //把怪物物理外形的种类掩码设为刚刚定义的 monsterCategory
        monster.physicsBody.categoryBitMask = monsterCategory
        //当发生碰撞时，当前怪物对象会通知它contactTestBitMask 这个属性所代表的category。这里应该把子弹的种类掩码projectileCategory赋给它
        monster.physicsBody.contactTestBitMask = projectileCategory
        //collisionBitMask 这个属性表示哪些种类的对象与当前怪物对象相碰撞时物理引擎要让其有所反应（比如回弹效果）。你并不想让怪物和子弹彼此之间发生回弹，设置这个属性为0吧。当然这在其他游戏里是可能的
        monster.physicsBody.collisionBitMask = 0
    }
    
    func updateWithTimeSinceLastUpdate(timeSinceLast: CFTimeInterval) -> Void {
        self.lastSpawnTimeInterval += timeSinceLast
        if self.lastSpawnTimeInterval > 1 {
            self.lastSpawnTimeInterval = 0
            self.addMonster()
        }
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        let touch: AnyObject! = touches.anyObject()
        let location = touch.locationInNode(self)
        
        // 初始化子弹位置
        let projectTile = SKSpriteNode(imageNamed: "projectile")
        projectTile.position = player.position
        
        // 计算子弹移动的偏移量
        let offset = CGPoint(x: location.x - projectTile.position.x, y: location.y - projectTile.position.y)
        if offset.x <= 0 {
            return
        }
        
        addChild(projectTile)
        
        let length = sqrt(offset.x * offset.x + offset.y * offset.y)
        let direction = CGPoint(x: offset.x / length, y: offset.y / length)
        let shootAmount = CGPoint(x: direction.x * 1000, y: direction.y * 1000)
        let realDest = CGPoint(x: shootAmount.x + projectTile.position.x, y: shootAmount.y + projectTile.position.y)
        
        let velocity = 480.0 / 1.0
        let realMoveDuration = self.frame.size.width / velocity
        let actionMove = SKAction.moveTo(realDest, duration: realMoveDuration)
        let actionMoveDone = SKAction.removeFromParent()
        projectTile.runAction(SKAction.sequence([actionMove, actionMoveDone]))
        

        projectTile.physicsBody = SKPhysicsBody(rectangleOfSize: projectTile.size)
        projectTile.physicsBody.dynamic = true
        projectTile.physicsBody.categoryBitMask = projectileCategory
        projectTile.physicsBody.contactTestBitMask = monsterCategory
        projectTile.physicsBody.collisionBitMask = 0
        projectTile.physicsBody.usesPreciseCollisionDetection = true
        
        self.runAction(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
    }
   
    override func update(currentTime: CFTimeInterval) {
        var timeSinceLast = currentTime - lastUpdateTimeInterval
        lastUpdateTimeInterval = currentTime
        if timeSinceLast > 1 {
            timeSinceLast = 1.0 / 60.0
            lastUpdateTimeInterval = currentTime
        }

        updateWithTimeSinceLastUpdate(timeSinceLast)
    }
    
    func didCollideWithMonster(projectile: SKNode, monster: SKNode) {
        projectile.removeFromParent()
        monster.removeFromParent()
        
        self.monsterDestroyed++
        if self.monsterDestroyed > 20 {
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let gameOverScene = GameOverScene(size: self.size, won: true)
            self.view.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact!) {
        var firstBody: SKPhysicsBody!
        var secondBody: SKPhysicsBody!
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            secondBody = contact.bodyA
            firstBody = contact.bodyB
        }
        
        if (firstBody.categoryBitMask & projectileCategory != 0) && (secondBody.categoryBitMask & monsterCategory != 0) {
            didCollideWithMonster(firstBody.node, monster: secondBody.node)
        }
    }
}
