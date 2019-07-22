//
//  ViewController.swift
//  CardViewAnimation
//
//  Created by MB on 7/23/19.
//  Copyright © 2019 MB. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    enum CardState{
        case expanded
        case collapsed
    }
    
    
    //referenced to cardViewcontroller
    var cardViewController : CardViewController!
    
    //for visual blur behind (UIVisualEffect can animate the intensity of blur)
    var visualEffectView : UIVisualEffectView!
    
    //Cards Height
    let cardHeight : CGFloat = 600
    //Cards handleArea height
    let cardHandleAreaHeight : CGFloat = 65
    
    //Next State to display
    var cardVisible = false //true if card is expanded
    var nextState : CardState{ //computed property
        return cardVisible ? .collapsed : .expanded
    }
    
    /*
     resize our cardView, blur in background, corner radius for animations
    */
    var runningAnimations = [UIViewPropertyAnimator]()
    
    /*
     To make animations interuptable
    */
    var animationProgressWhenInterrupted : CGFloat = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCard()
    }


    
    func setupCard(){
        
        //adding the blur effect
        visualEffectView = UIVisualEffectView()
        visualEffectView.frame = self.view.frame
        self.view.addSubview(visualEffectView)
       
        //loading cardViewController
        cardViewController = CardViewController(nibName : "CardViewController", bundle : nil)
        
        //adding cardViewController as a child to main ViewController
        self.addChild(cardViewController)
        //With this we only have cardViewController but we do not have its view thereefore
        self.view.addSubview(cardViewController.view)
        
        //frame of cardView View
        cardViewController.view.frame = CGRect(x: 0, y: self.view.frame.height - cardHandleAreaHeight, width: self.view.bounds.width, height: cardHeight )
        
        //A Boolean value that determines whether subviews are confined to the bounds of the view.
        cardViewController.view.clipsToBounds = true
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleCardTap(recognizer:)))
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ViewController.handleCardPan(recognizer:)))
        
        cardViewController.handleArea.addGestureRecognizer(tapGestureRecognizer)
        cardViewController.handleArea.addGestureRecognizer(panGestureRecognizer)
        
    }
    
    
    //tapping
    @objc
    func handleCardTap(recognizer : UITapGestureRecognizer){
        switch recognizer.state {
        case .ended:
            animateTransitionIfNeeded(state: nextState, duration: 0.9)
        default:
            break
        }
    }
    
    //panning interactive
    @objc
    func handleCardPan(recognizer : UIPanGestureRecognizer){
        switch recognizer.state {
        case .began:
            //startTransition
            startInteractiveTransition(state: nextState, duration: 0.9)
        case .changed:
            //updateTransition
            
            let translation = recognizer.translation(in: self.cardViewController.handleArea)
            
            var fractionComplete = translation.y / cardHeight
            fractionComplete = cardVisible ? fractionComplete : -fractionComplete
            
            updateInteractiveTransition(fractionCompleted: fractionComplete)
        case .ended:
            //continueTransition
            continueInteractiveTransition()
        default:
            break
        }
    }
    
    func animateTransitionIfNeeded(state : CardState,duration : TimeInterval){
        
        if runningAnimations.isEmpty{
            
            //create animation
            let frameAnimator = UIViewPropertyAnimator(duration: duration,
                                                       dampingRatio: 1) {
                                                        switch state{
                                                        case .expanded:
                                                            self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardHeight
                                                        case .collapsed:
                                                            self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardHandleAreaHeight
                                                        }
            }
            
            //visible falg when animation is completed
            frameAnimator.addCompletion { _ in
                self.cardVisible.toggle()
                //as we completed all animation we remove all animations in array as we no longer need it
                self.runningAnimations.removeAll()
            }
            
            //start animation
            frameAnimator.startAnimation()
            
            //appending for multiple animation
            runningAnimations.append(frameAnimator)
            
            
            let cornerRadiusAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
                switch state{
                case .expanded:
                    self.cardViewController.view.layer.cornerRadius = 12
                case .collapsed:
                    self.cardViewController.view.layer.cornerRadius = 0
                }
            }
            
            cornerRadiusAnimator.startAnimation()
            runningAnimations.append(cornerRadiusAnimator)
            
            let blurAnimator = UIViewPropertyAnimator(duration: duration,
                                                      dampingRatio: 1) {
                                                        switch state{
                                                        case .expanded:
                                                            self.visualEffectView.effect = UIBlurEffect(style: .dark)
                                                        case .collapsed:
                                                            self.visualEffectView.effect = nil
                                                        }
            }
            
            
            blurAnimator.startAnimation()
            runningAnimations.append(blurAnimator)
            
        }
        
    }
    
    
    //startTransition
    func startInteractiveTransition(state : CardState,duration:TimeInterval){
        if runningAnimations.isEmpty{
        //run animations
            animateTransitionIfNeeded(state: state, duration: duration)
        }
        
        for animator in runningAnimations{
            animator.pauseAnimation() //set the speed of animation to 0 by doing it we make interaction possible
            animationProgressWhenInterrupted = animator.fractionComplete //The completion percentage of the animation
        }
        
    }
    
    //updateTrarnsition
    func updateInteractiveTransition(fractionCompleted : CGFloat){
        // we just need to update fractionComplete of all of our animation , moving finger upward or downward
        for animator in runningAnimations{
        animator.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
        }
        
    }
    
    //continueTransition
    func continueInteractiveTransition(){
        
        for animator in runningAnimations{
            //setting it 0 means rproperty animator using remaining duration from we mentioned to complete the animation i.e. 0.9
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
        
    }
}

