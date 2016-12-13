//
//  ViewController.swift
//  Sample
//
//  Created by Roy Marmelstein on 10/04/2016.
//  Copyright © 2016 Roy Marmelstein. All rights reserved.
//

import UIKit
import Interpolate

class ViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    let groundView = UIView()
    let logoView = UIImageView()
    let bojackView = UIImageView()
    let bojackShadowView = UIImageView()
    
    let initialBackgroundColor = UIColor(red: 84.0/255.0, green: 187.0/255.0, blue: 253.0/255.0, alpha: 1.0)

    // Interpolations
    var backgroundColorChange: Interpolate?
    var groundPosition: Interpolate?
    var bojackPosition: Interpolate?
    var bojackShadowPosition: Interpolate?
    var logoAlpha: Interpolate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = initialBackgroundColor
        scrollView.contentSize = CGSize(width: self.view.bounds.size.width*2, height: self.view.bounds.size.height)
        
        // Logo view
        let logoImage = UIImage(named: "BojackLogo")!
        logoView.image = logoImage
        scrollView.addSubview(logoView)
        logoView.frame.size = logoImage.size
        logoView.center = CGPoint(x: self.view.bounds.size.width/2, y: 100)

        // Bojack view
        let bojackImage = UIImage(named: "Bojack")!
        bojackView.image = bojackImage
        scrollView.addSubview(bojackView)
        bojackView.frame.size = bojackImage.size
        bojackView.frame.origin = CGPoint(x: (self.view.bounds.size.width - bojackView.frame.size.width)/2, y: self.view.bounds.size.height - bojackView.frame.size.height)
       
        // Bojack shadow view
        let bojackShadowImage = UIImage(named: "BojackShadow")!
        bojackShadowView.image = bojackShadowImage
        self.view.addSubview(bojackShadowView)
        bojackShadowView.frame.size = bojackShadowImage.size
        bojackShadowView.frame.origin = CGPoint(x: -bojackShadowView.frame.size.width, y: self.view.bounds.size.height - 150 - bojackShadowView.frame.size.height)
        
        // Ground view
        groundView.backgroundColor = UIColor.black
        self.view.addSubview(groundView)
        groundView.frame.origin = CGPoint(x: 0, y: self.view.bounds.size.height)
        groundView.frame.size = CGSize(width: self.view.bounds.size.width, height: 300)

        self.view.bringSubview(toFront: pageControl)
        
        self.setupInterpolations()
    }
    
    func setupInterpolations() {
        let colors: [UIColor] = [initialBackgroundColor, UIColor(red: 255.0/255.0, green: 80.0/255.0, blue: 43.0/255.0, alpha: 1.0), UIColor.green]
        backgroundColorChange = Interpolate(values: colors, apply: { [weak self]  (color) in
            self?.view.backgroundColor = color
        })
        
        logoAlpha = Interpolate(from: 1.0, to: 0.0, apply: { [weak self] (alpha) in
            self?.logoView.alpha = alpha
        })
        
        bojackPosition  = Interpolate(from: (self.view.bounds.size.width - bojackView.frame.size.width)/2, to: -bojackView.frame.size.width, apply: { [weak self] (originX) in
            self?.bojackView.frame.origin.x = originX
        })

        bojackShadowPosition = Interpolate(from: -bojackShadowView.frame.size.width, to: (self.view.bounds.size.width - bojackShadowView.frame.size.width)/2, function: SpringInterpolation(damping: 30.0, velocity: 0.0, mass: 1.0, stiffness: 100.0), apply: { [weak self] (originX) in
            self?.bojackShadowView.frame.origin.x = originX
        })
        
        groundPosition = Interpolate(from: CGPoint(x: 0, y: self.view.bounds.size.height), to: CGPoint(x: 0, y: self.view.bounds.size.height - 150), function: BasicInterpolation.easeOut, apply: { [weak self] (origin) in
            self?.groundView.frame.origin = origin
        })
        
    }
    
    //MARK: UIScrollViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollProgress = scrollView.contentOffset.x / (scrollView.contentSize.width - scrollView.frame.size.width)
        let currentPage = scrollView.contentOffset.x / scrollView.frame.size.width
        pageControl.currentPage = lround(Double(currentPage))
        let groundProgress = scrollView.contentOffset.x / (scrollView.contentSize.width - 1.5*scrollView.frame.size.width)
        backgroundColorChange?.progress = scrollProgress
        logoAlpha?.progress = scrollProgress
        groundPosition?.progress = groundProgress
        bojackPosition?.progress = groundProgress
        bojackShadowPosition?.progress = max(groundProgress - 1, 0)
    }

}

