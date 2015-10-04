//
//  ViewController.swift
//  CardioTest
//
//  Created by Nestor Bermudez Sarmiento on 9/5/15.
//  Copyright © 2015 Nestor Bermudez. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPageViewControllerDataSource {

    var pageViewController: UIPageViewController!
    var pageTitles: NSArray!
    var pageImages: NSArray!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.pageTitles = NSArray(objects: "Explore", "Today")
        self.pageImages = NSArray(objects: "page1", "page2")

        self.pageViewController = self.storyboard?.instantiateViewControllerWithIdentifier("PageViewController") as! UIPageViewController
        self.pageViewController.dataSource = self

        let startVC = self.viewControllerAtAction(0)

        self.pageViewController.setViewControllers([startVC], direction: .Forward, animated: true, completion: nil)
        self.pageViewController.view.frame = CGRectMake(0, 30, self.view.frame.width, self.view.frame.size.height - 30)

        self.addChildViewController(self.pageViewController)
        self.view.addSubview(self.pageViewController.view)
        self.pageViewController.didMoveToParentViewController(self)
        self.configureDefaults()
    }

    private func configureDefaults() {
        let sharedDefaults = NSUserDefaults(suiteName: "group.com.agilityfeat.cardio911")
        NSUserDefaults.standardUserDefaults().registerDefaults(["contactNumber":"+13122398676"])
        sharedDefaults?.synchronize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func viewControllerAtAction(index: Int) -> ContentViewController {
        if (self.pageTitles.count == 0 || index >= self.pageTitles.count) {
            return ContentViewController()
        }

        let vc: ContentViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ContentViewController") as! ContentViewController
        vc.imageFile = self.pageImages[index] as! String
        vc.titleText = self.pageTitles[index] as! String
        vc.pageIndex = index

        return vc
    }

    // MARK: Page View Controller Data Source

    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        let vc = viewController as! ContentViewController
        var index = vc.pageIndex as Int

        if (index == 0 || index == NSNotFound) {
            return nil
        }

        index--
        return self.viewControllerAtAction(index)
    }

    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        let vc = viewController as! ContentViewController
        var index = vc.pageIndex as Int

        if (index == NSNotFound) {
            return nil
        }

        index++
        if (index == self.pageTitles.count) {
            return nil
        }

        return self.viewControllerAtAction(index)
    }

    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return self.pageTitles.count
    }

    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }
}

