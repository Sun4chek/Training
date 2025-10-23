//
//  TabBarController.swift
//  Tracker
//
//  Created by Волошин Александр on 8/27/25.
//

import UIKit

class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVc()
//        customizeTabBar()
        addCustomSeparator()
    }
    
    private func addCustomSeparator() {
        // Создаем view для разделительной линии
        let separatorView = UIView()
        separatorView.backgroundColor = .systemGray4
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        
        tabBar.addSubview(separatorView)
        
        NSLayoutConstraint.activate([
            separatorView.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
            separatorView.topAnchor.constraint(equalTo: tabBar.topAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5) // Толщина линии
        ])
    }

    func setupVc() {
        let trackerVc = UINavigationController(rootViewController: MainViewController())
        let trackers = NSLocalizedString("trackers", comment: "")
        trackerVc.tabBarItem = UITabBarItem(
            title: trackers,
            image: UIImage(systemName: "record.circle"),
            selectedImage: UIImage(systemName: "record.circle.fill")
        )
        let statisticsVC = UINavigationController(rootViewController: StatisticsViewController())
        let statistic = NSLocalizedString("statistic", comment: "")
               statisticsVC.tabBarItem = UITabBarItem(
                title: statistic,
                   image: UIImage(named:"staticIcon"),
                   selectedImage: UIImage(named:  "staticfilled")
               )
        viewControllers = [trackerVc, statisticsVC]
    }
    
    private func customizeTabBar() {
        tabBar.shadowImage = UIImage()
    }
    
}


